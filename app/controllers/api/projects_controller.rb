class Api::ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :update, :destroy]

  def index
    projects = Project.includes(:owner, :created_by, :tasks)
                      .order(updated_at: :desc)

    # Filter by status
    projects = projects.by_status(params[:status]) if params[:status].present?

    # Filter active only (default)
    projects = projects.active if params[:include_complete] != "true" && params[:status].blank?

    render json: projects.map { |project| project_json(project) }
  end

  def show
    render json: project_json(@project, full: true)
  end

  def create
    project = Project.new(project_params)

    if project.save
      render json: project_json(project, full: true), status: :created
    else
      render json: { errors: project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @project.update(project_params)
      render json: project_json(@project, full: true)
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    render json: { success: true }
  end

  private

  def set_project
    @project = Project.includes(:owner, :created_by, :tasks).find(params[:id])
  end

  def project_params
    params.require(:project).permit(
      :name, :description, :status, :owner_id, :created_by_id
    )
  end

  def project_json(project, full: false)
    data = {
      id: project.id,
      name: project.name,
      description: project.description,
      status: project.status,
      owner: project.owner ? {
        id: project.owner.id,
        firstName: project.owner.first_name,
        lastName: project.owner.last_name
      } : nil,
      createdBy: project.created_by ? {
        id: project.created_by.id,
        firstName: project.created_by.first_name,
        lastName: project.created_by.last_name
      } : nil,
      openTasksCount: project.open_tasks_count,
      overdueTasksCount: project.overdue_tasks_count,
      tasksCompletionPercent: project.tasks_completion_percent,
      createdAt: project.created_at,
      updatedAt: project.updated_at
    }

    if full
      data[:tasks] = {
        overdue: project.tasks.overdue.by_due_date.map { |t| task_json(t) },
        dueThisWeek: project.tasks.open_tasks.due_this_week.by_due_date.reject(&:overdue?).map { |t| task_json(t) },
        backlog: project.tasks.open_tasks.by_due_date.reject { |t| t.overdue? || t.due_this_week? }.map { |t| task_json(t) },
        completed: project.tasks.completed_tasks.recent.limit(10).map { |t| task_json(t) }
      }
    end

    data
  end

  def task_json(task)
    {
      id: task.id,
      subject: task.subject,
      body: task.body,
      dueAt: task.due_at,
      completed: task.completed,
      overdue: task.overdue?,
      priority: task.priority,
      priorityLabel: task.priority_label,
      status: task.status,
      isSubtask: task.subtask?,
      parentTaskId: task.parent_task_id,
      subtaskCount: task.subtask_count,
      completedSubtaskCount: task.completed_subtask_count,
      assignedTo: task.assigned_to ? {
        id: task.assigned_to.id,
        firstName: task.assigned_to.first_name,
        lastName: task.assigned_to.last_name
      } : nil,
      createdAt: task.created_at
    }
  end
end

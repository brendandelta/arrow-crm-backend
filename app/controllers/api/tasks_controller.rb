class Api::TasksController < ApplicationController
  before_action :set_task, only: [:show, :update, :destroy, :complete, :uncomplete]

  def index
    tasks = Task.includes(:assigned_to, :created_by, :parent_task, :subtasks, :deal, :organization, :person)
                .order(created_at: :desc)

    # Filter by entity
    tasks = tasks.for_deal(params[:deal_id]) if params[:deal_id].present?
    tasks = tasks.for_organization(params[:organization_id]) if params[:organization_id].present?
    tasks = tasks.for_person(params[:person_id]) if params[:person_id].present?

    # Filter by status
    tasks = tasks.open_tasks if params[:status] == "open"
    tasks = tasks.completed_tasks if params[:status] == "completed"
    tasks = tasks.overdue if params[:status] == "overdue"

    # Filter by assignee
    tasks = tasks.assigned_to_user(params[:assigned_to_id]) if params[:assigned_to_id].present?

    # Filter root tasks only or subtasks only
    tasks = tasks.root_tasks if params[:root_only] == "true"
    tasks = tasks.subtasks_only if params[:subtasks_only] == "true"

    render json: tasks.map { |task| task_json(task) }
  end

  def show
    render json: task_json(@task, full: true)
  end

  def create
    task = Task.new(task_params)

    if task.save
      render json: task_json(task, full: true), status: :created
    else
      render json: { errors: task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @task.update(task_params)
      render json: task_json(@task, full: true)
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy
    render json: { success: true }
  end

  # POST /api/tasks/:id/complete
  def complete
    @task.complete!
    render json: task_json(@task, full: true)
  end

  # POST /api/tasks/:id/uncomplete
  def uncomplete
    @task.uncomplete!
    render json: task_json(@task, full: true)
  end

  # GET /api/tasks/my_tasks
  def my_tasks
    # This would use current_user when authentication is implemented
    # For now, can filter by assigned_to_id
    tasks = Task.includes(:assigned_to, :deal, :organization, :person)
                .open_tasks
                .by_due_date

    tasks = tasks.assigned_to_user(params[:user_id]) if params[:user_id].present?

    # Group by due status
    result = {
      overdue: tasks.overdue.map { |t| task_json(t) },
      dueToday: tasks.due_today.map { |t| task_json(t) },
      dueThisWeek: tasks.due_this_week.reject { |t| t.due_today? || t.overdue? }.map { |t| task_json(t) },
      upcoming: tasks.upcoming.reject { |t| t.due_this_week? }.limit(20).map { |t| task_json(t) },
      noDueDate: tasks.no_due_date.map { |t| task_json(t) }
    }

    render json: result
  end

  # GET /api/tasks/grouped
  def grouped
    tasks = Task.includes(:assigned_to, :deal, :organization, :person)
                .order(Arel.sql("CASE WHEN due_at IS NULL THEN 1 ELSE 0 END, due_at ASC"))

    # Filter by entity if provided
    tasks = tasks.for_deal(params[:deal_id]) if params[:deal_id].present?
    tasks = tasks.for_organization(params[:organization_id]) if params[:organization_id].present?
    tasks = tasks.for_person(params[:person_id]) if params[:person_id].present?

    open_tasks = tasks.open_tasks
    completed_tasks = tasks.completed_tasks.recent.limit(50)

    result = {
      overdue: open_tasks.overdue.map { |t| task_json(t) },
      dueThisWeek: open_tasks.due_this_week.reject(&:overdue?).map { |t| task_json(t) },
      backlog: open_tasks.reject { |t| t.overdue? || t.due_this_week? }.map { |t| task_json(t) },
      completed: completed_tasks.map { |t| task_json(t) }
    }

    render json: result
  end

  private

  def set_task
    @task = Task.includes(:assigned_to, :created_by, :parent_task, :subtasks, :deal, :organization, :person)
                .find(params[:id])
  end

  def task_params
    params.require(:task).permit(
      :subject, :body, :due_at, :completed, :priority, :status,
      :parent_task_id, :assigned_to_id, :created_by_id,
      :deal_id, :organization_id, :person_id
    )
  end

  def task_json(task, full: false)
    data = {
      id: task.id,
      subject: task.subject,
      body: task.body,
      dueAt: task.due_at,
      completed: task.completed,
      completedAt: task.completed_at,
      priority: task.priority,
      priorityLabel: task.priority_label,
      status: task.status,
      overdue: task.overdue?,
      dueToday: task.due_today?,
      dueThisWeek: task.due_this_week?,
      isSubtask: task.subtask?,
      parentTaskId: task.parent_task_id,
      subtaskCount: task.subtask_count,
      completedSubtaskCount: task.completed_subtask_count,
      subtaskCompletionPercent: task.subtask_completion_percent,
      assignedTo: task.assigned_to ? {
        id: task.assigned_to.id,
        firstName: task.assigned_to.first_name,
        lastName: task.assigned_to.last_name,
        email: task.assigned_to.email
      } : nil,
      createdBy: task.created_by ? {
        id: task.created_by.id,
        firstName: task.created_by.first_name,
        lastName: task.created_by.last_name
      } : nil,
      dealId: task.deal_id,
      organizationId: task.organization_id,
      personId: task.person_id,
      linkedEntityType: task.linked_entity_type,
      linkedEntityName: task.linked_entity_name,
      createdAt: task.created_at,
      updatedAt: task.updated_at
    }

    if full
      data[:parentTask] = task.parent_task ? {
        id: task.parent_task.id,
        subject: task.parent_task.subject
      } : nil
      data[:subtasks] = task.subtasks.map { |st| task_json(st) }
      data[:deal] = task.deal ? { id: task.deal.id, name: task.deal.name } : nil
      data[:organization] = task.organization ? { id: task.organization.id, name: task.organization.name } : nil
      data[:person] = task.person ? { id: task.person.id, name: task.person.full_name } : nil
      data[:metadata] = task.metadata
    end

    data
  end
end

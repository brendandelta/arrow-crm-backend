class Api::InterestsController < ApplicationController
  before_action :set_interest, only: [:show, :update, :destroy]

  def index
    interests = Interest.includes(:deal, :investor, :contact, :decision_maker, :tasks, deal: :company)
                        .order(created_at: :desc)

    render json: interests.map { |interest| interest_json(interest) }
  end

  def show
    render json: interest_json(@interest, full: true)
  end

  def create
    interest = Interest.new(interest_params)

    if interest.save
      render json: { id: interest.id, success: true }, status: :created
    else
      render json: { errors: interest.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @interest.update(interest_params)
      render json: interest_json(@interest, full: true)
    else
      render json: { errors: @interest.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @interest.destroy
    render json: { success: true }
  end

  private

  def set_interest
    @interest = Interest.includes(:deal, :investor, :contact, :decision_maker, :tasks, deal: :company).find(params[:id])
  end

  def interest_params
    params.permit(
      :deal_id, :investor_id, :contact_id, :decision_maker_id,
      :target_cents, :min_cents, :max_cents, :committed_cents, :allocated_cents,
      :status, :pass_reason, :pass_notes, :allocated_block_id,
      :wired_at, :wire_amount_cents, :source, :source_detail,
      :introduced_by_id, :owner_id, :internal_notes,
      :next_step, :next_step_at
    )
  end

  def taskable_task_json(task)
    {
      id: task.id,
      subject: task.subject,
      dueAt: task.due_at,
      completed: task.completed,
      priority: task.priority,
      priorityLabel: task.priority_label,
      status: task.status,
      overdue: task.overdue?,
      assignedTo: task.assigned_to ? {
        id: task.assigned_to.id,
        firstName: task.assigned_to.first_name,
        lastName: task.assigned_to.last_name
      } : nil
    }
  end

  def next_task_json(tasks)
    next_task = tasks.select { |t| !t.completed? }.min_by { |t| t.due_at || Time.new(9999) }
    return nil unless next_task

    {
      id: next_task.id,
      subject: next_task.subject,
      dueAt: next_task.due_at,
      overdue: next_task.overdue?,
      assignedTo: next_task.assigned_to ? {
        id: next_task.assigned_to.id,
        firstName: next_task.assigned_to.first_name,
        lastName: next_task.assigned_to.last_name
      } : nil
    }
  end

  def interest_json(interest, full: false)
    data = {
      id: interest.id,
      dealId: interest.deal_id,
      dealName: interest.deal&.name,
      underlyingCompany: interest.deal&.company ? {
        id: interest.deal.company.id,
        name: interest.deal.company.name
      } : nil,
      investor: interest.investor ? {
        id: interest.investor.id,
        name: interest.investor.name,
        kind: interest.investor.kind
      } : nil,
      contact: interest.contact ? {
        id: interest.contact.id,
        firstName: interest.contact.first_name,
        lastName: interest.contact.last_name,
        title: interest.contact.title,
        email: interest.contact.primary_email,
        phone: interest.contact.primary_phone
      } : nil,
      decisionMaker: interest.decision_maker ? {
        id: interest.decision_maker.id,
        firstName: interest.decision_maker.first_name,
        lastName: interest.decision_maker.last_name
      } : nil,
      targetCents: interest.target_cents,
      minCents: interest.min_cents,
      maxCents: interest.max_cents,
      committedCents: interest.committed_cents,
      allocatedCents: interest.allocated_cents,
      allocatedBlockId: interest.allocated_block_id,
      status: interest.status,
      source: interest.source,
      sourceDetail: interest.source_detail,
      nextStep: interest.next_step,
      nextStepAt: interest.next_step_at,
      tasks: interest.tasks.select { |t| !t.completed? }.sort_by { |t| t.due_at || Time.new(9999) }.map { |t| taskable_task_json(t) },
      nextTask: next_task_json(interest.tasks),
      createdAt: interest.created_at,
      updatedAt: interest.updated_at
    }

    if full
      data[:passReason] = interest.pass_reason
      data[:passNotes] = interest.pass_notes
      data[:wiredAt] = interest.wired_at
      data[:wireAmountCents] = interest.wire_amount_cents
      data[:internalNotes] = interest.internal_notes
      data[:firstContactedAt] = interest.first_contacted_at
      data[:lastContactedAt] = interest.last_contacted_at
      data[:meetingsCount] = interest.meetings_count
    end

    data
  end
end

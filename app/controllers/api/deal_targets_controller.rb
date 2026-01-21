class Api::DealTargetsController < ApplicationController
  before_action :set_deal_target, only: [:show, :update, :destroy]

  # GET /api/deal_targets
  # GET /api/deals/:deal_id/targets
  def index
    deal_targets = if params[:deal_id]
      DealTarget.where(deal_id: params[:deal_id])
    else
      DealTarget.all
    end

    deal_targets = deal_targets.includes(:deal, :target, :owner)
                               .order(priority: :asc, last_activity_at: :desc)

    # Optional filters
    deal_targets = deal_targets.where(status: params[:status]) if params[:status].present?
    deal_targets = deal_targets.where(target_type: params[:target_type]) if params[:target_type].present?

    render json: deal_targets.map { |dt| deal_target_json(dt) }
  end

  # GET /api/deal_targets/:id
  def show
    render json: deal_target_json(@deal_target, full: true)
  end

  # POST /api/deal_targets
  def create
    deal_target = DealTarget.new(deal_target_params)

    if deal_target.save
      render json: deal_target_json(deal_target), status: :created
    else
      render json: { errors: deal_target.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/deal_targets/bulk_create
  # Create multiple targets at once (for adding a list of targets to a deal)
  def bulk_create
    targets = params[:targets] || []
    deal_id = params[:deal_id]

    return render json: { errors: ["deal_id is required"] }, status: :unprocessable_entity unless deal_id

    created = []
    errors = []

    targets.each do |target|
      dt = DealTarget.new(
        deal_id: deal_id,
        target_type: target[:target_type],
        target_id: target[:target_id],
        status: target[:status] || "not_started",
        role: target[:role],
        priority: target[:priority] || 2,
        owner_id: target[:owner_id],
        notes: target[:notes]
      )

      if dt.save
        created << deal_target_json(dt)
      else
        errors << { target: target, errors: dt.errors.full_messages }
      end
    end

    render json: { created: created, errors: errors }, status: errors.any? ? :multi_status : :created
  end

  # PATCH /api/deal_targets/:id
  def update
    if @deal_target.update(deal_target_params)
      render json: deal_target_json(@deal_target, full: true)
    else
      render json: { errors: @deal_target.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/deal_targets/bulk_update
  def bulk_update
    ids = params[:ids] || []
    updates = params[:updates] || {}

    return render json: { errors: ["ids array is required"] }, status: :unprocessable_entity if ids.empty?

    deal_targets = DealTarget.where(id: ids)

    if deal_targets.update_all(updates.permit(:status, :priority, :role, :owner_id, :next_step, :next_step_at).to_h)
      render json: { success: true, updated: ids.count }
    else
      render json: { errors: ["Failed to update targets"] }, status: :unprocessable_entity
    end
  end

  # DELETE /api/deal_targets/:id
  def destroy
    @deal_target.destroy
    render json: { success: true }
  end

  # DELETE /api/deal_targets/bulk_delete
  def bulk_delete
    ids = params[:ids] || []
    return render json: { errors: ["ids array is required"] }, status: :unprocessable_entity if ids.empty?

    deleted_count = DealTarget.where(id: ids).destroy_all.count
    render json: { success: true, deleted: deleted_count }
  end

  private

  def set_deal_target
    @deal_target = DealTarget.includes(:deal, :target, :owner, :activities).find(params[:id])
  end

  def deal_target_params
    params.permit(
      :deal_id, :target_type, :target_id, :status, :role, :priority,
      :first_contacted_at, :last_contacted_at, :next_step, :next_step_at,
      :notes, :owner_id
    )
  end

  def deal_target_json(deal_target, full: false)
    target = deal_target.target

    data = {
      id: deal_target.id,
      dealId: deal_target.deal_id,
      dealName: deal_target.deal&.name,
      targetType: deal_target.target_type,
      targetId: deal_target.target_id,
      targetName: deal_target.target_name,
      target: target_summary(target, deal_target.target_type),
      status: deal_target.status,
      role: deal_target.role,
      priority: deal_target.priority,
      priorityLabel: deal_target.priority_label,
      firstContactedAt: deal_target.first_contacted_at,
      lastContactedAt: deal_target.last_contacted_at,
      lastActivityAt: deal_target.last_activity_at,
      activityCount: deal_target.activity_count,
      nextStep: deal_target.next_step,
      nextStepAt: deal_target.next_step_at,
      owner: deal_target.owner ? {
        id: deal_target.owner.id,
        firstName: deal_target.owner.first_name,
        lastName: deal_target.owner.last_name
      } : nil,
      createdAt: deal_target.created_at,
      updatedAt: deal_target.updated_at
    }

    if full
      data[:notes] = deal_target.notes
      data[:activities] = deal_target.activities.recent.limit(10).map { |a| activity_summary(a) }
    end

    data
  end

  def target_summary(target, target_type)
    return nil unless target

    case target_type
    when "Organization"
      {
        id: target.id,
        name: target.name,
        kind: target.kind,
        website: target.website,
        location: target.location,
        warmth: target.warmth
      }
    when "Person"
      {
        id: target.id,
        firstName: target.first_name,
        lastName: target.last_name,
        email: target.primary_email,
        phone: target.primary_phone,
        title: target.current_title,
        organization: target.current_org ? {
          id: target.current_org.id,
          name: target.current_org.name
        } : nil,
        warmth: target.warmth
      }
    end
  end

  def activity_summary(activity)
    {
      id: activity.id,
      kind: activity.kind,
      subject: activity.subject,
      occurredAt: activity.occurred_at,
      outcome: activity.outcome
    }
  end
end

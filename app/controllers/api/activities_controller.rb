class Api::ActivitiesController < ApplicationController
  before_action :set_activity, only: [:show, :update, :destroy, :complete_task]

  # GET /api/activities
  # Supports filtering by regarding (polymorphic), deal, deal_target, kind, etc.
  def index
    activities = Activity.includes(:deal_target, :deal, :performed_by, :assigned_to, :activity_attendees)
                         .order(occurred_at: :desc)

    # Filter by polymorphic regarding
    if params[:regarding_type].present? && params[:regarding_id].present?
      activities = activities.where(regarding_type: params[:regarding_type], regarding_id: params[:regarding_id])
    end

    # Filter by deal_target
    activities = activities.where(deal_target_id: params[:deal_target_id]) if params[:deal_target_id].present?

    # Filter by deal
    activities = activities.where(deal_id: params[:deal_id]) if params[:deal_id].present?

    # Filter by kind
    activities = activities.where(kind: params[:kind]) if params[:kind].present?

    # Filter by task status
    if params[:tasks_only] == "true"
      activities = activities.tasks
      activities = activities.open_tasks if params[:open_only] == "true"
      activities = activities.overdue_tasks if params[:overdue_only] == "true"
    end

    # Filter for meetings/scheduled activities only
    if params[:meetings_only] == "true" || params[:scheduled_only] == "true"
      activities = activities.meetings
    end

    # Time-based filters for scheduled activities
    case params[:time_filter]
    when "upcoming"
      activities = activities.upcoming
    when "past"
      activities = activities.past
    when "today"
      activities = activities.on_date(Date.current)
    when "this_week"
      activities = activities.in_range(Date.current.beginning_of_week, Date.current.end_of_week)
    end

    # Date range filter
    if params[:from].present?
      activities = activities.where("occurred_at >= ?", Time.parse(params[:from]))
    end
    if params[:to].present?
      activities = activities.where("occurred_at <= ?", Time.parse(params[:to]))
    end

    # Pagination
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 50).to_i
    activities = activities.limit(per_page).offset((page - 1) * per_page)

    render json: activities.map { |a| activity_json(a) }
  end

  # GET /api/activities/:id
  def show
    render json: activity_json(@activity, full: true)
  end

  # POST /api/activities
  def create
    activity = Activity.new(activity_params)
    activity.occurred_at ||= Time.current

    # For meetings, set occurred_at to starts_at if not provided
    if activity.meeting? && activity.starts_at.present? && activity.occurred_at == Time.current
      activity.occurred_at = activity.starts_at
    end

    if activity.save
      # Handle attendees if provided
      process_attendees(activity) if params[:attendees].present?

      render json: activity_json(activity, include_attendees: true), status: :created
    else
      render json: { errors: activity.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/activities/:id
  def update
    if @activity.update(activity_params)
      # Handle attendees if provided
      process_attendees(@activity) if params[:attendees].present?

      render json: activity_json(@activity, full: true, include_attendees: true)
    else
      render json: { errors: @activity.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/activities/:id
  def destroy
    @activity.destroy
    render json: { success: true }
  end

  # POST /api/activities/:id/complete_task
  def complete_task
    unless @activity.is_task?
      return render json: { errors: ["Activity is not a task"] }, status: :unprocessable_entity
    end

    @activity.complete_task!
    render json: activity_json(@activity)
  end

  # GET /api/activities/timeline
  # Get a unified timeline of activities for a deal (across all targets)
  def timeline
    return render json: { errors: ["deal_id is required"] }, status: :bad_request unless params[:deal_id]

    deal = Deal.find(params[:deal_id])

    # Get activities directly on the deal
    deal_activities = deal.activities

    # Get activities on all deal targets
    target_activities = Activity.where(deal_target_id: deal.deal_target_ids)

    # Combine and sort
    all_activities = Activity.where(id: deal_activities.pluck(:id) + target_activities.pluck(:id))
                             .includes(:deal_target, :performed_by)
                             .order(occurred_at: :desc)
                             .limit(100)

    render json: all_activities.map { |a| activity_json(a, include_target: true) }
  end

  # GET /api/activities/tasks
  # Get all open tasks (across all deals/targets)
  def tasks
    tasks = Activity.open_tasks
                    .includes(:deal_target, :deal, :assigned_to, :performed_by)
                    .order(task_due_at: :asc)

    tasks = tasks.where(assigned_to_id: params[:assigned_to_id]) if params[:assigned_to_id].present?
    tasks = tasks.where(deal_id: params[:deal_id]) if params[:deal_id].present?
    tasks = tasks.overdue_tasks if params[:overdue_only] == "true"

    render json: tasks.map { |t| activity_json(t, include_target: true) }
  end

  # GET /api/activities/calendar
  # Get scheduled activities (meetings) for calendar view
  def calendar
    start_date = params[:start] ? Date.parse(params[:start]) : Date.current.beginning_of_month
    end_date = params[:end] ? Date.parse(params[:end]) : Date.current.end_of_month

    activities = Activity.scheduled
                         .in_range(start_date.beginning_of_day, end_date.end_of_day)
                         .includes(:deal, :activity_attendees, :performed_by)
                         .order(starts_at: :asc)

    activities = activities.where(deal_id: params[:deal_id]) if params[:deal_id].present?
    activities = activities.where(kind: params[:kind]) if params[:kind].present?

    render json: activities.map { |a| activity_json(a, include_attendees: true) }
  end

  private

  def set_activity
    @activity = Activity.includes(:deal_target, :deal, :performed_by, :assigned_to).find(params[:id])
  end

  def activity_params
    params.permit(
      :kind, :subject, :body, :direction, :outcome, :occurred_at, :duration_minutes,
      :regarding_type, :regarding_id, :deal_target_id, :deal_id,
      :performed_by_id, :is_task, :task_completed, :task_due_at, :assigned_to_id,
      # Meeting/calendar fields
      :starts_at, :ends_at, :location, :location_type, :meeting_url, :timezone, :all_day,
      :calendar_id, :calendar_provider, :calendar_url,
      metadata: {}
    )
  end

  def process_attendees(activity)
    attendees = params[:attendees] || []

    # Clear existing attendees and re-add
    activity.activity_attendees.destroy_all

    attendees.each do |attendee_params|
      case attendee_params[:type]
      when "Person"
        person = Person.find_by(id: attendee_params[:id])
        activity.add_attendee(person, role: attendee_params[:role], is_organizer: attendee_params[:is_organizer]) if person
      when "User"
        user = User.find_by(id: attendee_params[:id])
        activity.add_attendee(user, role: attendee_params[:role], is_organizer: attendee_params[:is_organizer]) if user
      when "external"
        activity.add_attendee(
          { email: attendee_params[:email], name: attendee_params[:name] },
          role: attendee_params[:role],
          is_organizer: attendee_params[:is_organizer]
        )
      end
    end
  end

  def activity_json(activity, full: false, include_target: false, include_attendees: false)
    data = {
      id: activity.id,
      kind: activity.kind,
      subject: activity.subject,
      direction: activity.direction,
      outcome: activity.outcome,
      occurredAt: activity.occurred_at,
      durationMinutes: activity.duration_minutes,
      regardingType: activity.regarding_type,
      regardingId: activity.regarding_id,
      dealTargetId: activity.deal_target_id,
      dealId: activity.deal_id,
      dealName: activity.deal&.name,
      performedBy: activity.performed_by ? {
        id: activity.performed_by.id,
        firstName: activity.performed_by.first_name,
        lastName: activity.performed_by.last_name
      } : nil,
      isTask: activity.is_task,
      taskCompleted: activity.task_completed,
      taskDueAt: activity.task_due_at,
      isOverdue: activity.overdue?,
      assignedTo: activity.assigned_to ? {
        id: activity.assigned_to.id,
        firstName: activity.assigned_to.first_name,
        lastName: activity.assigned_to.last_name
      } : nil,
      # Meeting/calendar fields
      startsAt: activity.starts_at,
      endsAt: activity.ends_at,
      location: activity.location,
      locationType: activity.location_type,
      meetingUrl: activity.meeting_url,
      timezone: activity.timezone,
      allDay: activity.all_day,
      isScheduled: activity.scheduled?,
      isUpcoming: activity.scheduled? ? activity.upcoming? : nil,
      attendeeCount: activity.activity_attendees.size,
      createdAt: activity.created_at,
      updatedAt: activity.updated_at
    }

    if full
      data[:body] = activity.body
      data[:metadata] = activity.metadata
      data[:calendarId] = activity.calendar_id
      data[:calendarProvider] = activity.calendar_provider
      data[:calendarUrl] = activity.calendar_url
    end

    if include_target && activity.deal_target
      data[:dealTarget] = {
        id: activity.deal_target.id,
        targetType: activity.deal_target.target_type,
        targetId: activity.deal_target.target_id,
        targetName: activity.deal_target.target_name,
        status: activity.deal_target.status
      }
    end

    if include_attendees || full
      data[:attendees] = activity.activity_attendees.map { |aa| attendee_json(aa) }
    end

    data
  end

  def attendee_json(attendee)
    {
      id: attendee.id,
      type: attendee.attendee_type,
      attendeeId: attendee.attendee_id,
      email: attendee.email,
      name: attendee.display_name,
      role: attendee.role,
      responseStatus: attendee.response_status,
      isOrganizer: attendee.is_organizer
    }
  end
end

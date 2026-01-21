class Api::MeetingsController < ApplicationController
  # GET /api/meetings
  def index
    meetings = Meeting.includes(:deal, :organization).order(starts_at: :desc)

    # Filter by deal
    meetings = meetings.where(deal_id: params[:deal_id]) if params[:deal_id].present?

    # Filter by organization
    meetings = meetings.where(organization_id: params[:organization_id]) if params[:organization_id].present?

    # Filter by attendee (person)
    if params[:attendee_id].present?
      meetings = meetings.where("? = ANY(attendee_ids)", params[:attendee_id].to_i)
    end

    # Filter by kind
    meetings = meetings.where(kind: params[:kind]) if params[:kind].present?

    # Filter by date range
    meetings = meetings.where("starts_at >= ?", params[:from]) if params[:from].present?
    meetings = meetings.where("starts_at <= ?", params[:to]) if params[:to].present?

    # Upcoming only
    meetings = meetings.upcoming if params[:upcoming] == "true"

    # Past only
    meetings = meetings.past if params[:past] == "true"

    render json: meetings.limit(100).map { |m| serialize_meeting_summary(m) }
  end

  # GET /api/meetings/:id
  def show
    meeting = Meeting.includes(:deal, :organization).find(params[:id])
    render json: serialize_meeting_detail(meeting)
  end

  # POST /api/meetings
  def create
    meeting = Meeting.new(meeting_params)

    if meeting.save
      render json: { id: meeting.id, success: true }, status: :created
    else
      render json: { errors: meeting.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/meetings/:id
  def update
    meeting = Meeting.find(params[:id])

    if meeting.update(meeting_params)
      render json: { id: meeting.id, success: true }
    else
      render json: { errors: meeting.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/meetings/:id
  def destroy
    meeting = Meeting.find(params[:id])
    meeting.destroy
    render json: { success: true }
  end

  private

  def meeting_params
    {
      title: params[:title],
      description: params[:description],
      kind: params[:kind],
      starts_at: params[:startsAt],
      ends_at: params[:endsAt],
      timezone: params[:timezone],
      all_day: params[:allDay],
      location: params[:location],
      location_type: params[:locationType],
      meeting_url: params[:meetingUrl],
      dial_in: params[:dialIn],
      address: params[:address],
      deal_id: params[:dealId],
      organization_id: params[:organizationId],
      attendee_ids: params[:attendeeIds] || [],
      internal_attendee_ids: params[:internalAttendeeIds] || [],
      external_attendees: params[:externalAttendees] || [],
      agenda: params[:agenda],
      summary: params[:summary],
      action_items: params[:actionItems],
      outcome: params[:outcome],
      follow_up_needed: params[:followUpNeeded],
      follow_up_at: params[:followUpAt],
      follow_up_notes: params[:followUpNotes],
      tags: params[:tags] || []
    }.compact
  end

  def serialize_meeting_summary(meeting)
    {
      id: meeting.id,
      title: meeting.title,
      kind: meeting.kind,
      startsAt: meeting.starts_at,
      endsAt: meeting.ends_at,
      location: meeting.location,
      dealId: meeting.deal_id,
      dealName: meeting.deal&.name,
      organizationId: meeting.organization_id,
      organizationName: meeting.organization&.name,
      attendeeCount: meeting.attendee_ids&.length || 0
    }
  end

  def serialize_meeting_detail(meeting)
    # Get attendee details
    attendees = if meeting.attendee_ids.present?
      Person.where(id: meeting.attendee_ids).map do |p|
        {
          id: p.id,
          firstName: p.first_name,
          lastName: p.last_name,
          email: p.primary_email,
          avatarUrl: p.avatar.attached? ? url_for(p.avatar) : p.avatar_url
        }
      end
    else
      []
    end

    {
      id: meeting.id,
      title: meeting.title,
      description: meeting.description,
      kind: meeting.kind,
      startsAt: meeting.starts_at,
      endsAt: meeting.ends_at,
      timezone: meeting.timezone,
      allDay: meeting.all_day,
      isRecurring: meeting.is_recurring,
      recurrenceRule: meeting.recurrence_rule,
      location: meeting.location,
      locationType: meeting.location_type,
      meetingUrl: meeting.meeting_url,
      dialIn: meeting.dial_in,
      address: meeting.address,
      dealId: meeting.deal_id,
      dealName: meeting.deal&.name,
      organizationId: meeting.organization_id,
      organizationName: meeting.organization&.name,
      attendees: attendees,
      externalAttendees: meeting.external_attendees,
      gcalUrl: meeting.gcal_url,
      agenda: meeting.agenda,
      summary: meeting.summary,
      actionItems: meeting.action_items,
      transcriptUrl: meeting.transcript_url,
      recordingUrl: meeting.recording_url,
      outcome: meeting.outcome,
      followUpNeeded: meeting.follow_up_needed,
      followUpAt: meeting.follow_up_at,
      followUpNotes: meeting.follow_up_notes,
      tags: meeting.tags || [],
      createdAt: meeting.created_at,
      updatedAt: meeting.updated_at
    }
  end
end

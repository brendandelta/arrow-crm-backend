class Activity < ApplicationRecord
  belongs_to :regarding, polymorphic: true  # Deal, Organization, Person, DealTarget
  belongs_to :deal_target, optional: true
  belongs_to :deal, optional: true
  belongs_to :performed_by, class_name: "User", optional: true
  belongs_to :assigned_to, class_name: "User", optional: true

  # Attendees for meetings
  has_many :activity_attendees, dependent: :destroy
  has_many :person_attendees, through: :activity_attendees, source: :attendee, source_type: "Person"
  has_many :user_attendees, through: :activity_attendees, source: :attendee, source_type: "User"

  validates :kind, presence: true
  validates :regarding_type, presence: true
  validates :regarding_id, presence: true
  validates :occurred_at, presence: true

  # Activity types - unified across all interaction types
  KINDS = %w[call email meeting in_person_meeting video_call whatsapp sms linkedin_message linkedin_connection note task].freeze
  validates :kind, inclusion: { in: KINDS }

  # Meeting kinds for easy filtering
  MEETING_KINDS = %w[meeting in_person_meeting video_call].freeze

  # Location types for meetings
  LOCATION_TYPES = %w[virtual in_person phone].freeze
  validates :location_type, inclusion: { in: LOCATION_TYPES }, allow_nil: true

  # Direction for communications
  DIRECTIONS = %w[inbound outbound].freeze
  validates :direction, inclusion: { in: DIRECTIONS }, allow_nil: true

  # Outcomes
  OUTCOMES = %w[connected voicemail no_answer left_message replied bounced opened scheduled completed cancelled no_show].freeze
  validates :outcome, inclusion: { in: OUTCOMES }, allow_nil: true

  scope :calls, -> { where(kind: "call") }
  scope :emails, -> { where(kind: "email") }
  scope :meetings, -> { where(kind: %w[meeting in_person_meeting video_call]) }
  scope :messages, -> { where(kind: %w[whatsapp sms linkedin_message]) }
  scope :notes, -> { where(kind: "note") }
  scope :tasks, -> { where(is_task: true) }
  scope :open_tasks, -> { where(is_task: true, task_completed: false) }
  scope :completed_tasks, -> { where(is_task: true, task_completed: true) }
  scope :overdue_tasks, -> { where(is_task: true, task_completed: false).where("task_due_at < ?", Time.current) }

  scope :inbound, -> { where(direction: "inbound") }
  scope :outbound, -> { where(direction: "outbound") }
  scope :recent, -> { order(occurred_at: :desc) }
  scope :chronological, -> { order(occurred_at: :asc) }
  scope :today, -> { where(occurred_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :this_week, -> { where(occurred_at: Time.current.beginning_of_week..Time.current.end_of_week) }

  # Calendar/scheduling scopes
  scope :scheduled, -> { where.not(starts_at: nil) }
  scope :upcoming, -> { scheduled.where("starts_at > ?", Time.current).order(starts_at: :asc) }
  scope :past, -> { scheduled.where("starts_at < ?", Time.current).order(starts_at: :desc) }
  scope :on_date, ->(date) { scheduled.where(starts_at: date.beginning_of_day..date.end_of_day) }
  scope :in_range, ->(start_date, end_date) { scheduled.where(starts_at: start_date..end_date) }

  # Kind helpers
  def call? = kind == "call"
  def email? = kind == "email"
  def meeting? = kind.in?(%w[meeting in_person_meeting video_call])
  def message? = kind.in?(%w[whatsapp sms linkedin_message])
  def note? = kind == "note"
  def task? = is_task?

  # Task helpers
  def overdue?
    is_task? && !task_completed? && task_due_at && task_due_at < Time.current
  end

  def complete_task!
    update!(task_completed: true) if is_task?
  end

  # Meeting helpers
  def scheduled?
    starts_at.present?
  end

  def duration_minutes
    return super if super.present?
    return nil unless starts_at && ends_at
    ((ends_at - starts_at) / 60).to_i
  end

  def upcoming?
    scheduled? && starts_at > Time.current
  end

  def past?
    scheduled? && starts_at < Time.current
  end

  def virtual?
    location_type == "virtual"
  end

  def in_person?
    location_type == "in_person"
  end

  # Attendee helpers
  def attendee_count
    activity_attendees.count
  end

  def add_attendee(attendee, role: "attendee", is_organizer: false)
    case attendee
    when Person
      activity_attendees.find_or_create_by!(attendee_type: "Person", attendee_id: attendee.id) do |aa|
        aa.email = attendee.primary_email
        aa.name = attendee.full_name
        aa.role = role
        aa.is_organizer = is_organizer
      end
    when User
      activity_attendees.find_or_create_by!(attendee_type: "User", attendee_id: attendee.id) do |aa|
        aa.email = attendee.email
        aa.name = "#{attendee.first_name} #{attendee.last_name}"
        aa.role = role
        aa.is_organizer = is_organizer
      end
    when Hash
      # External attendee
      activity_attendees.find_or_create_by!(attendee_type: "external", email: attendee[:email]) do |aa|
        aa.name = attendee[:name]
        aa.role = role
        aa.is_organizer = is_organizer
      end
    end
  end

  # Callbacks to update deal_target tracking
  after_create :update_deal_target_tracking
  after_destroy :recalculate_deal_target_tracking

  private

  def update_deal_target_tracking
    return unless deal_target.present?
    deal_target.record_activity!
  end

  def recalculate_deal_target_tracking
    return unless deal_target.present?
    # Recalculate activity count and last activity
    last_activity = deal_target.activities.where.not(id: id).order(occurred_at: :desc).first
    deal_target.update!(
      activity_count: deal_target.activities.where.not(id: id).count,
      last_activity_at: last_activity&.occurred_at,
      last_contacted_at: last_activity&.occurred_at
    )
  end
end

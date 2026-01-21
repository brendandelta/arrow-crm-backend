class ActivityAttendee < ApplicationRecord
  belongs_to :activity
  belongs_to :attendee, polymorphic: true, optional: true  # Person, User, or nil for external

  validates :attendee_type, presence: true
  validates :attendee_type, inclusion: { in: %w[Person User external] }

  # Either attendee_id (for Person/User) or email (for external) must be present
  validate :attendee_identifier_present

  ROLES = %w[organizer attendee optional].freeze
  validates :role, inclusion: { in: ROLES }, allow_nil: true

  RESPONSE_STATUSES = %w[accepted declined tentative needs_action].freeze
  validates :response_status, inclusion: { in: RESPONSE_STATUSES }, allow_nil: true

  scope :organizers, -> { where(is_organizer: true) }
  scope :accepted, -> { where(response_status: "accepted") }
  scope :declined, -> { where(response_status: "declined") }
  scope :pending, -> { where(response_status: %w[tentative needs_action]) }

  scope :people, -> { where(attendee_type: "Person") }
  scope :users, -> { where(attendee_type: "User") }
  scope :external, -> { where(attendee_type: "external") }

  def organizer?
    is_organizer?
  end

  def external?
    attendee_type == "external"
  end

  def display_name
    return name if name.present?
    return attendee.full_name if attendee_type == "Person" && attendee
    return "#{attendee.first_name} #{attendee.last_name}" if attendee_type == "User" && attendee
    email
  end

  private

  def attendee_identifier_present
    if attendee_type == "external"
      errors.add(:email, "is required for external attendees") if email.blank?
    else
      errors.add(:attendee_id, "is required for Person/User attendees") if attendee_id.blank?
    end
  end
end

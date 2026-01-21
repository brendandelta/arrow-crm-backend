class Meeting < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true
  belongs_to :deal, optional: true
  belongs_to :organization, optional: true

  validates :title, presence: true
  validates :starts_at, presence: true

  scope :upcoming, -> { where("starts_at > ?", Time.current).order(:starts_at) }
  scope :past, -> { where("starts_at <= ?", Time.current).order(starts_at: :desc) }
  scope :today, -> { where(starts_at: Date.current.all_day) }
  scope :this_week, -> { where(starts_at: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :by_kind, ->(kind) { where(kind: kind) }
  scope :calls, -> { where(kind: "call") }
  scope :in_person, -> { where(kind: "in_person") }
  scope :video, -> { where(kind: "video") }
  # Note: is_completed column doesn't exist yet - remove these scopes or add migration
  # scope :completed, -> { where(is_completed: true) }
  # scope :pending, -> { where(is_completed: false) }

  def call? = kind == "call"
  def in_person? = kind == "in_person"
  def video? = kind == "video"
  def email? = kind == "email"

  def duration_minutes
    return nil unless starts_at && ends_at
    ((ends_at - starts_at) / 60).to_i
  end

  def attendees
    return [] if attendee_ids.blank?
    Person.where(id: attendee_ids)
  end

  def attendee_count
    attendee_ids&.length || 0
  end

  def past?
    starts_at < Time.current
  end

  def upcoming?
    starts_at > Time.current
  end

  def happening_now?
    return false unless ends_at
    Time.current.between?(starts_at, ends_at)
  end
end

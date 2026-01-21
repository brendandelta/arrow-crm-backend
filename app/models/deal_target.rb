class DealTarget < ApplicationRecord
  belongs_to :deal
  belongs_to :target, polymorphic: true  # Organization or Person
  belongs_to :owner, class_name: "User", optional: true
  has_many :activities, dependent: :destroy

  validates :deal_id, presence: true
  validates :target_type, presence: true, inclusion: { in: %w[Organization Person] }
  validates :target_id, presence: true
  validates :status, presence: true
  validates :deal_id, uniqueness: { scope: [:target_type, :target_id], message: "already has this target" }

  # Status workflow for outreach
  STATUSES = %w[not_started contacted engaged negotiating committed passed on_hold].freeze
  validates :status, inclusion: { in: STATUSES }

  # Priority levels
  PRIORITIES = { now: 0, high: 1, medium: 2, low: 3 }.freeze
  validates :priority, inclusion: { in: PRIORITIES.values }

  # Roles for targets
  ROLES = %w[lead_investor co_investor advisor strategic_partner other].freeze
  validates :role, inclusion: { in: ROLES }, allow_nil: true

  scope :not_started, -> { where(status: "not_started") }
  scope :contacted, -> { where(status: "contacted") }
  scope :engaged, -> { where(status: "engaged") }
  scope :negotiating, -> { where(status: "negotiating") }
  scope :committed, -> { where(status: "committed") }
  scope :passed, -> { where(status: "passed") }
  scope :on_hold, -> { where(status: "on_hold") }
  scope :active, -> { where(status: %w[not_started contacted engaged negotiating]) }
  scope :by_priority, -> { order(priority: :asc) }
  scope :recently_active, -> { order(last_activity_at: :desc) }
  scope :needs_followup, -> { where("next_step_at <= ?", Time.current) }

  scope :organizations, -> { where(target_type: "Organization") }
  scope :people, -> { where(target_type: "Person") }

  # Status helpers
  def not_started? = status == "not_started"
  def contacted? = status == "contacted"
  def engaged? = status == "engaged"
  def negotiating? = status == "negotiating"
  def committed? = status == "committed"
  def passed? = status == "passed"
  def on_hold? = status == "on_hold"

  # Priority helpers
  def priority_label
    PRIORITIES.key(priority)&.to_s&.titleize || "Medium"
  end

  # Record an activity and update tracking fields
  def record_activity!
    now = Time.current
    update!(
      last_activity_at: now,
      activity_count: activity_count + 1,
      first_contacted_at: first_contacted_at || now,
      last_contacted_at: now
    )
  end

  # Get the target name for display
  def target_name
    case target_type
    when "Organization"
      target.name
    when "Person"
      "#{target.first_name} #{target.last_name}"
    end
  end
end

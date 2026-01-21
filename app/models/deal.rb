class Deal < ApplicationRecord
  belongs_to :company, class_name: "Organization"
  belongs_to :owner, class_name: "User", optional: true
  has_many :blocks, dependent: :destroy
  has_many :interests, dependent: :destroy
  has_many :meetings, dependent: :nullify
  has_many :documents, as: :parent, dependent: :destroy
  has_many :notes, as: :parent, dependent: :destroy
  has_many :deal_targets, dependent: :destroy
  has_many :activities, dependent: :destroy

  validates :name, presence: true
  validates :status, presence: true

  # Deal type: primary or secondary
  KINDS = %w[primary secondary].freeze
  validates :kind, presence: true, inclusion: { in: KINDS }

  # Deal owner entity (not the user, but which company owns the deal)
  DEAL_OWNERS = %w[arrow liberator].freeze
  validates :deal_owner, inclusion: { in: DEAL_OWNERS }, allow_nil: true

  # Priority levels
  PRIORITIES = { now: 0, high: 1, medium: 2, low: 3 }.freeze
  validates :priority, inclusion: { in: PRIORITIES.values }, allow_nil: true

  scope :active, -> { where(status: %w[sourcing live closing]) }
  scope :closed, -> { where(status: "closed") }
  scope :dead, -> { where(status: "dead") }
  scope :by_status, ->(status) { where(status: status) }
  scope :tagged, ->(tag) { where("? = ANY(tags)", tag) }
  scope :in_sector, ->(sector) { where(sector: sector) }
  scope :direct, -> { where(is_direct: true) }
  scope :brokered, -> { where(is_direct: false) }
  scope :primary, -> { where(kind: "primary") }
  scope :secondary, -> { where(kind: "secondary") }
  scope :owned_by_arrow, -> { where(deal_owner: "arrow") }
  scope :owned_by_liberator, -> { where(deal_owner: "liberator") }
  scope :by_priority, -> { order(priority: :asc) }

  def sourcing? = status == "sourcing"
  def live? = status == "live"
  def closing? = status == "closing"
  def closed? = status == "closed"
  def dead? = status == "dead"
  def primary? = kind == "primary"
  def secondary? = kind == "secondary"

  # Priority helper
  def priority_label
    PRIORITIES.key(priority)&.to_s&.titleize || "Medium"
  end

  # Soft circle aggregation from interests
  def soft_circled_cents
    interests.where(status: "soft_circled").sum(:committed_cents)
  end

  def soft_circled_dollars
    soft_circled_cents.to_f / 100
  end

  # Total committed from interests (all statuses that indicate commitment)
  def total_committed_cents
    interests.where(status: %w[soft_circled committed funded]).sum(:committed_cents)
  end

  def total_committed_dollars
    total_committed_cents.to_f / 100
  end

  # Outreach target helpers
  def target_organizations
    deal_targets.organizations.includes(:target)
  end

  def target_people
    deal_targets.people.includes(:target)
  end

  def active_targets
    deal_targets.active.includes(:target)
  end

  def committed_dollars
    committed_cents.to_f / 100 if committed_cents
  end

  def closed_dollars
    closed_cents.to_f / 100 if closed_cents
  end

  def target_valuation_dollars
    target_valuation_cents.to_f / 100 if target_valuation_cents
  end

  def share_price_dollars
    share_price_cents.to_f / 100 if share_price_cents
  end

  def progress_percent
    return 0 unless committed_cents&.positive?
    return 100 if closed_cents.to_i >= committed_cents
    ((closed_cents.to_f / committed_cents) * 100).round(1)
  end

  def days_since_launch
    return nil unless launched_at
    (Date.current - launched_at.to_date).to_i
  end
end

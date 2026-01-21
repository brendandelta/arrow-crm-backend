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
  has_many :advantages, dependent: :destroy

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

  # Wired/funded amount from interests
  def wired_cents
    interests.funded.sum(:committed_cents)
  end

  def wired_dollars
    wired_cents.to_f / 100
  end

  # Inventory from available blocks
  def inventory_cents
    blocks.available.sum(:total_cents)
  end

  def inventory_dollars
    inventory_cents.to_f / 100
  end

  # Coverage ratio: committed / inventory
  def coverage_ratio
    return nil if inventory_cents.nil? || inventory_cents.zero?
    (total_committed_cents.to_f / inventory_cents * 100).round(1)
  end

  # Best priced available block
  def best_price_block
    blocks.available.where.not(price_cents: nil).order(price_cents: :asc).first
  end

  # Next deadline - earliest of close date, deadline, or task due
  def next_deadline
    dates = []
    dates << { date: expected_close, type: "expected_close", label: "Expected Close" } if expected_close
    dates << { date: deadline, type: "deadline", label: "Deadline" } if deadline

    # Get earliest overdue or upcoming task
    next_task = activities.where(is_task: true, task_completed: false)
                         .where.not(task_due_at: nil)
                         .order(task_due_at: :asc)
                         .first
    dates << { date: next_task.task_due_at.to_date, type: "task", label: next_task.subject || "Task due" } if next_task

    dates.min_by { |d| d[:date] }
  end

  # Days until close date
  def days_until_close
    return nil unless expected_close
    (expected_close.to_date - Date.current).to_i
  end

  # Auto-compute risk flags based on deal state
  def compute_risk_flags
    flags = {}

    # Pricing stale: no price updates in 30+ days on blocks
    latest_block_update = blocks.maximum(:updated_at)
    if latest_block_update && latest_block_update < 30.days.ago
      flags[:pricing_stale] = {
        active: true,
        message: "Block pricing not updated in 30+ days",
        severity: "warning"
      }
    end

    # Coverage low: committed < 50% of inventory
    if inventory_cents&.positive? && coverage_ratio && coverage_ratio < 50
      flags[:coverage_low] = {
        active: true,
        message: "Coverage ratio below 50%",
        severity: "warning"
      }
    end

    # Missing docs: critical diligence documents missing
    required_docs = Document::DILIGENCE_KINDS rescue []
    if required_docs.any?
      existing_kinds = documents.pluck(:kind).compact
      missing = required_docs - existing_kinds
      if missing.any?
        flags[:missing_docs] = {
          active: true,
          message: "Missing #{missing.count} required documents",
          missing: missing,
          severity: "info"
        }
      end
    end

    # Deadline risk: closing within 7 days with low coverage
    if days_until_close && days_until_close <= 7 && days_until_close >= 0
      if coverage_ratio.nil? || coverage_ratio < 80
        flags[:deadline_risk] = {
          active: true,
          message: "Close date in #{days_until_close} days with #{coverage_ratio || 0}% coverage",
          severity: "danger"
        }
      end
    end

    # Stale outreach: active targets with no activity in 7+ days
    stale_targets = deal_targets.active.where("last_activity_at < ? OR last_activity_at IS NULL", 7.days.ago).count
    if stale_targets > 0
      flags[:stale_outreach] = {
        active: true,
        message: "#{stale_targets} targets need follow-up",
        count: stale_targets,
        severity: "warning"
      }
    end

    # Overdue tasks
    overdue_count = activities.overdue_tasks.count
    if overdue_count > 0
      flags[:overdue_tasks] = {
        active: true,
        message: "#{overdue_count} overdue tasks",
        count: overdue_count,
        severity: "danger"
      }
    end

    flags
  end

  # Update risk flags and save
  def update_risk_flags!
    update!(risk_flags: compute_risk_flags)
  end

  # Tasks summary
  def tasks_summary
    tasks = activities.where(is_task: true)
    {
      total: tasks.count,
      completed: tasks.completed_tasks.count,
      overdue: tasks.overdue_tasks.count,
      due_this_week: tasks.open_tasks.where(task_due_at: Time.current..Time.current.end_of_week).count
    }
  end

  # Demand funnel counts
  def demand_funnel
    {
      prospecting: interests.prospecting.count,
      contacted: interests.contacted.count,
      soft_circled: interests.soft_circled.count,
      committed: interests.committed.count,
      allocated: interests.allocated.count,
      funded: interests.funded.count,
      declined: interests.declined.count,
      withdrawn: interests.withdrawn.count
    }
  end

  # Biggest constraint - determine what's blocking progress
  def biggest_constraint
    # Check various constraints in priority order
    if inventory_cents.nil? || inventory_cents.zero?
      return { type: "no_inventory", message: "No available inventory" }
    end

    if interests.active.count.zero?
      return { type: "no_demand", message: "No active investor interest" }
    end

    overdue = tasks_summary[:overdue]
    if overdue > 0
      return { type: "overdue_tasks", message: "#{overdue} overdue tasks blocking progress" }
    end

    missing_docs = compute_risk_flags[:missing_docs]
    if missing_docs && missing_docs[:missing]&.any?
      return { type: "missing_docs", message: "Missing critical documents: #{missing_docs[:missing].first}" }
    end

    stale = compute_risk_flags[:stale_outreach]
    if stale && stale[:count] > 3
      return { type: "stale_outreach", message: "#{stale[:count]} targets awaiting follow-up" }
    end

    nil
  end
end

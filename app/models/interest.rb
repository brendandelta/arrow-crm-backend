class Interest < ApplicationRecord
  belongs_to :deal
  belongs_to :investor, class_name: "Organization"
  belongs_to :contact, class_name: "Person", optional: true
  belongs_to :decision_maker, class_name: "Person", optional: true
  belongs_to :introduced_by, class_name: "Person", optional: true
  belongs_to :allocated_block, class_name: "Block", optional: true
  belongs_to :owner, class_name: "User", optional: true
  has_many :tasks, as: :taskable, dependent: :nullify

  validates :deal_id, presence: true
  validates :investor_id, presence: true
  validates :status, presence: true

  # Status workflow for interests
  STATUSES = %w[prospecting contacted soft_circled committed allocated funded declined withdrawn].freeze
  validates :status, inclusion: { in: STATUSES }

  scope :prospecting, -> { where(status: "prospecting") }
  scope :contacted, -> { where(status: "contacted") }
  scope :soft_circled, -> { where(status: "soft_circled") }
  scope :committed, -> { where(status: "committed") }
  scope :allocated, -> { where(status: "allocated") }
  scope :funded, -> { where(status: "funded") }
  scope :declined, -> { where(status: "declined") }
  scope :withdrawn, -> { where(status: "withdrawn") }
  scope :active, -> { where(status: %w[prospecting contacted soft_circled committed allocated]) }
  scope :with_commitment, -> { where(status: %w[soft_circled committed allocated funded]) }

  # Legacy scopes for backward compatibility
  scope :pending, -> { where(status: "prospecting") }
  scope :approved, -> { where(status: "soft_circled") }

  def prospecting? = status == "prospecting"
  def contacted? = status == "contacted"
  def soft_circled? = status == "soft_circled"
  def committed? = status == "committed"
  def allocated? = status == "allocated"
  def funded? = status == "funded"
  def declined? = status == "declined"
  def withdrawn? = status == "withdrawn"

  # Legacy helpers for backward compatibility
  def pending? = status == "prospecting"
  def approved? = status == "soft_circled"

  def target_dollars
    target_cents.to_f / 100 if target_cents
  end

  def committed_dollars
    committed_cents.to_f / 100 if committed_cents
  end

  def funded_dollars
    funded_cents.to_f / 100 if funded_cents
  end

  def max_price_dollars
    max_price_cents.to_f / 100 if max_price_cents
  end

  def fulfillment_percent
    return 0 unless committed_cents&.positive?
    return 100 if funded_cents.to_i >= committed_cents
    ((funded_cents.to_f / committed_cents) * 100).round(1)
  end
end

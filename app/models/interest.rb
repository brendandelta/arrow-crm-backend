class Interest < ApplicationRecord
  belongs_to :deal
  belongs_to :investor, class_name: "Organization"
  belongs_to :owner, class_name: "User", optional: true

  validates :deal_id, presence: true
  validates :investor_id, presence: true
  validates :status, presence: true

  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :committed, -> { where(status: "committed") }
  scope :funded, -> { where(status: "funded") }
  scope :declined, -> { where(status: "declined") }
  scope :withdrawn, -> { where(status: "withdrawn") }
  scope :active, -> { where(status: %w[pending approved committed]) }

  def pending? = status == "pending"
  def approved? = status == "approved"
  def committed? = status == "committed"
  def funded? = status == "funded"
  def declined? = status == "declined"
  def withdrawn? = status == "withdrawn"

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

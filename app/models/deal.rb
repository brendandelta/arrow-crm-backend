class Deal < ApplicationRecord
  belongs_to :company, class_name: "Organization"
  belongs_to :owner, class_name: "User", optional: true
  has_many :blocks, dependent: :destroy
  has_many :interests, dependent: :destroy
  has_many :meetings, dependent: :nullify
  has_many :documents, as: :parent, dependent: :destroy
  has_many :notes, as: :parent, dependent: :destroy

  validates :name, presence: true
  validates :status, presence: true

  scope :active, -> { where(status: %w[sourcing live closing]) }
  scope :closed, -> { where(status: "closed") }
  scope :dead, -> { where(status: "dead") }
  scope :by_status, ->(status) { where(status: status) }
  scope :tagged, ->(tag) { where("? = ANY(tags)", tag) }
  scope :in_sector, ->(sector) { where(sector: sector) }
  scope :direct, -> { where(is_direct: true) }
  scope :brokered, -> { where(is_direct: false) }

  def sourcing? = status == "sourcing"
  def live? = status == "live"
  def closing? = status == "closing"
  def closed? = status == "closed"
  def dead? = status == "dead"

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

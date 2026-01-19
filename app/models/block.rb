class Block < ApplicationRecord
  belongs_to :deal
  belongs_to :seller, class_name: "Person"

  validates :deal_id, presence: true
  validates :seller_id, presence: true
  validates :status, presence: true

  scope :available, -> { where(status: "available") }
  scope :reserved, -> { where(status: "reserved") }
  scope :sold, -> { where(status: "sold") }
  scope :withdrawn, -> { where(status: "withdrawn") }
  scope :by_share_class, ->(share_class) { where(share_class: share_class) }

  def available? = status == "available"
  def reserved? = status == "reserved"
  def sold? = status == "sold"
  def withdrawn? = status == "withdrawn"

  def shares_offered_dollars
    shares_offered_cents.to_f / 100 if shares_offered_cents
  end

  def ask_price_dollars
    ask_price_cents.to_f / 100 if ask_price_cents
  end

  def min_price_dollars
    min_price_cents.to_f / 100 if min_price_cents
  end

  def total_value_at_ask
    return nil unless shares_offered && ask_price_cents
    (shares_offered * ask_price_cents).to_f / 100
  end

  def total_value_at_min
    return nil unless shares_offered && min_price_cents
    (shares_offered * min_price_cents).to_f / 100
  end
end

class Block < ApplicationRecord
  # Heat levels: cold (0), warm (1), hot (2), fire (3)
  HEAT_LEVELS = { cold: 0, warm: 1, hot: 2, fire: 3 }.freeze
  STATUSES = %w[available reserved sold withdrawn].freeze

  belongs_to :deal
  belongs_to :seller, class_name: "Organization", optional: true
  belongs_to :contact, class_name: "Person", optional: true
  belongs_to :broker, class_name: "Organization", optional: true
  belongs_to :broker_contact, class_name: "Person", optional: true

  has_many :interests, foreign_key: :allocated_block_id
  has_many :tasks, as: :taskable, dependent: :nullify
  has_many :block_contacts, dependent: :destroy
  has_many :linked_seller_contacts, -> { where(role: "seller_contact") }, class_name: "BlockContact"
  has_many :linked_broker_contacts, -> { where(role: "broker_contact") }, class_name: "BlockContact"

  validates :deal_id, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :heat, inclusion: { in: HEAT_LEVELS.values }, allow_nil: true

  scope :available, -> { where(status: "available") }
  scope :reserved, -> { where(status: "reserved") }
  scope :sold, -> { where(status: "sold") }
  scope :withdrawn, -> { where(status: "withdrawn") }
  scope :by_share_class, ->(share_class) { where(share_class: share_class) }
  scope :by_heat, ->(heat) { where(heat: heat) }
  scope :hot_or_fire, -> { where(heat: [2, 3]) }

  def available? = status == "available"
  def reserved? = status == "reserved"
  def sold? = status == "sold"
  def withdrawn? = status == "withdrawn"

  def heat_label
    HEAT_LEVELS.key(heat)&.to_s&.capitalize || "Cold"
  end

  def cold? = heat == 0
  def warm? = heat == 1
  def hot? = heat == 2
  def fire? = heat == 3

  # Underlying company comes from the deal
  def underlying_company
    deal&.company
  end

  # Get contacts from the seller organization
  def seller_contacts
    return [] unless seller
    seller.people.includes(:employments).where(employments: { is_current: true })
  end

  def allocation_dollars
    total_cents.to_f / 100 if total_cents
  end

  def price_per_share_dollars
    price_cents.to_f / 100 if price_cents
  end

  def min_size_dollars
    min_size_cents.to_f / 100 if min_size_cents
  end

  def constraints
    list = []
    list << "ROFR" if rofr?
    list << "Transfer Approval" if transfer_approval_required?
    list << "Issuer Approval" if issuer_approval_required?
    list
  end
end

class BlockContact < ApplicationRecord
  ROLES = %w[seller_contact broker_contact].freeze

  belongs_to :block
  belongs_to :person

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :person_id, uniqueness: { scope: [:block_id, :role], message: "already linked with this role" }

  scope :seller_contacts, -> { where(role: "seller_contact") }
  scope :broker_contacts, -> { where(role: "broker_contact") }
end

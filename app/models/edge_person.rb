class EdgePerson < ApplicationRecord
  belongs_to :edge
  belongs_to :person

  ROLES = %w[connector target source insider stakeholder].freeze

  validates :person_id, uniqueness: { scope: :edge_id, message: "is already linked to this edge" }
  validates :role, inclusion: { in: ROLES }, allow_nil: true

  scope :connectors, -> { where(role: "connector") }
  scope :targets, -> { where(role: "target") }
  scope :sources, -> { where(role: "source") }

  def connector? = role == "connector"
  def target? = role == "target"
  def source? = role == "source"
end

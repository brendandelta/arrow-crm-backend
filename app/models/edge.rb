class Edge < ApplicationRecord
  # Associations
  belongs_to :deal
  belongs_to :related_person, class_name: "Person", optional: true
  belongs_to :related_org, class_name: "Organization", optional: true
  belongs_to :created_by, class_name: "User", optional: true

  # Multiple people can be linked to an edge
  has_many :edge_people, dependent: :destroy
  has_many :people, through: :edge_people

  # Validations
  validates :title, presence: true
  validates :edge_type, presence: true

  EDGE_TYPES = %w[information relationship structural timing].freeze
  validates :edge_type, inclusion: { in: EDGE_TYPES }

  validates :confidence, presence: true, numericality: { only_integer: true, in: 1..5 }
  validates :timeliness, presence: true, numericality: { only_integer: true, in: 1..5 }

  # Scopes
  scope :by_type, ->(type) { where(edge_type: type) }
  scope :information, -> { where(edge_type: "information") }
  scope :relationship, -> { where(edge_type: "relationship") }
  scope :structural, -> { where(edge_type: "structural") }
  scope :timing, -> { where(edge_type: "timing") }

  scope :high_confidence, -> { where("confidence >= ?", 4) }
  scope :low_confidence, -> { where("confidence <= ?", 2) }
  scope :fresh, -> { where("timeliness >= ?", 4) }
  scope :stale, -> { where("timeliness <= ?", 2) }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_score, -> { order(Arel.sql("confidence * timeliness DESC")) }

  # Predicate methods
  def information? = edge_type == "information"
  def relationship? = edge_type == "relationship"
  def structural? = edge_type == "structural"
  def timing? = edge_type == "timing"

  def high_confidence? = confidence >= 4
  def fresh? = timeliness >= 4
  def stale? = timeliness <= 2

  # Composite score (confidence * timeliness) for ranking
  def score
    confidence * timeliness
  end

  # Label methods for UI display
  def confidence_label
    case confidence
    when 5 then "Very High"
    when 4 then "High"
    when 3 then "Medium"
    when 2 then "Low"
    when 1 then "Very Low"
    else "Unknown"
    end
  end

  def timeliness_label
    case timeliness
    when 5 then "Very Fresh"
    when 4 then "Fresh"
    when 3 then "Current"
    when 2 then "Aging"
    when 1 then "Stale"
    else "Unknown"
    end
  end

  def edge_type_label
    edge_type&.titleize || "Unknown"
  end
end

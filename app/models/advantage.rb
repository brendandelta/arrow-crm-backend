class Advantage < ApplicationRecord
  belongs_to :deal

  validates :kind, presence: true
  validates :title, presence: true

  KINDS = %w[pricing_edge relationship_edge timing_edge information_edge].freeze
  validates :kind, inclusion: { in: KINDS }

  TIMELINESS_LEVELS = %w[stale current fresh].freeze
  validates :timeliness, inclusion: { in: TIMELINESS_LEVELS }, allow_nil: true

  validates :confidence, numericality: { in: 1..5 }, allow_nil: true

  scope :by_kind, ->(kind) { where(kind: kind) }
  scope :fresh, -> { where(timeliness: "fresh") }
  scope :current, -> { where(timeliness: "current") }
  scope :stale, -> { where(timeliness: "stale") }
  scope :high_confidence, -> { where("confidence >= ?", 4) }
  scope :recent, -> { order(created_at: :desc) }

  def pricing_edge? = kind == "pricing_edge"
  def relationship_edge? = kind == "relationship_edge"
  def timing_edge? = kind == "timing_edge"
  def information_edge? = kind == "information_edge"

  def fresh? = timeliness == "fresh"
  def current? = timeliness == "current"
  def stale? = timeliness == "stale"

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
    timeliness&.titleize || "Unknown"
  end
end

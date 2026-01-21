class Organization < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true
  belongs_to :parent_org, class_name: "Organization", optional: true
  has_many :subsidiaries, class_name: "Organization", foreign_key: :parent_org_id, dependent: :nullify
  has_many :employments, dependent: :destroy
  has_many :people, through: :employments
  has_many :deals, foreign_key: :company_id, dependent: :destroy
  has_many :documents, as: :parent, dependent: :destroy
  has_many :notes, as: :parent, dependent: :destroy
  has_many :deal_targets, as: :target, dependent: :destroy
  has_many :activities, as: :regarding, dependent: :destroy
  has_many :targeted_deals, through: :deal_targets, source: :deal

  validates :name, presence: true
  validates :kind, presence: true

  scope :funds, -> { where(kind: "fund") }
  scope :companies, -> { where(kind: "company") }
  scope :spvs, -> { where(kind: "spv") }
  scope :brokers, -> { where(kind: "broker") }
  scope :law_firms, -> { where(kind: "law_firm") }
  scope :tagged, ->(tag) { where("? = ANY(tags)", tag) }
  scope :in_sector, ->(sector) { where(sector: sector) }
  scope :in_country, ->(country) { where(country: country) }
  scope :warm, -> { where(warmth: 1..) }
  scope :hot, -> { where(warmth: 2..) }
  scope :needs_follow_up, -> { where("next_follow_up_at <= ?", Date.current) }

  def fund? = kind == "fund"
  def company? = kind == "company"
  def spv? = kind == "spv"
  def broker? = kind == "broker"
  def law_firm? = kind == "law_firm"

  def location
    [city, state, country].compact.join(", ")
  end

  def full_address
    [address_line1, address_line2, city, state, postal_code, country].compact.join(", ")
  end

  def warmth_label
    %w[cold warm hot champion][warmth] || "unknown"
  end

  # Fund meta accessors
  def aum = meta&.dig("aum_cents")
  def strategies = meta&.dig("strategies") || []
  def stages = meta&.dig("stages") || []
  def geo_focus = meta&.dig("geo_focus") || []
  def sector_focus = meta&.dig("sector_focus") || []
  def check_min = meta&.dig("check_min_cents")
  def check_max = meta&.dig("check_max_cents")
  def sweet_spot = meta&.dig("sweet_spot_cents")
  def thesis = meta&.dig("thesis")
  def fund_size = meta&.dig("fund_size_cents")
  def vintage_year = meta&.dig("vintage_year")

  # Company meta accessors
  def valuation = meta&.dig("valuation_cents")
  def total_raised = meta&.dig("total_raised_cents")
  def last_round = meta&.dig("last_round")
  def last_round_date = meta&.dig("last_round_date")
  def founded_year = meta&.dig("founded_year")
  def employee_count = meta&.dig("employee_count")
  def has_rofr? = meta&.dig("has_rofr") == true
  def rofr_days = meta&.dig("rofr_days")
  def transfer_restrictions = meta&.dig("transfer_restrictions")

  # SPV meta accessors
  def ein = meta&.dig("ein")
  def platform = meta&.dig("platform")
  def managing_member = meta&.dig("managing_member")
  def formed_at = meta&.dig("formed_at")
end

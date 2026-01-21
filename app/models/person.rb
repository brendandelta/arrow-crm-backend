class Person < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true
  has_many :employments, dependent: :destroy
  has_many :organizations, through: :employments
  has_many :documents, as: :parent, dependent: :destroy
  has_many :notes, as: :parent, dependent: :destroy
  has_many :deal_targets, as: :target, dependent: :destroy
  has_many :activities, as: :regarding, dependent: :destroy
  has_many :targeted_deals, through: :deal_targets, source: :deal

  # Avatar image attachment (stored on AWS S3)
  # This single line gives us: person.avatar, person.avatar.attach(), person.avatar.attached?, etc.
  has_one_attached :avatar

  validates :first_name, presence: true
  validates :last_name, presence: true

  scope :warm, -> { where(warmth: 1..) }
  scope :hot, -> { where(warmth: 2..) }
  scope :champions, -> { where(warmth: 3) }
  scope :cold, -> { where(warmth: 0) }
  scope :tagged, ->(tag) { where("? = ANY(tags)", tag) }
  scope :in_country, ->(country) { where(country: country) }
  scope :in_state, ->(state) { where(state: state) }
  scope :in_city, ->(city) { where(city: city) }
  scope :needs_follow_up, -> { where("next_follow_up_at <= ?", Date.current) }
  scope :not_contacted_since, ->(days) { where("last_contacted_at < ?", days.days.ago) }

  def full_name
    [first_name, last_name].compact.join(" ")
  end

  def formal_name
    [prefix, first_name, last_name, suffix].compact.join(" ")
  end

  def display_name
    nickname.presence || first_name
  end

  def primary_email
    emails&.find { |e| e["primary"] }&.dig("value")
  end

  def primary_phone
    phones&.find { |p| p["primary"] }&.dig("value")
  end

  def all_emails
    emails&.map { |e| e["value"] } || []
  end

  def all_phones
    phones&.map { |p| p["value"] } || []
  end

  def current_employment
    employments.find_by(is_current: true, is_primary: true) || employments.find_by(is_current: true)
  end

  def current_org
    current_employment&.organization
  end

  def current_title
    current_employment&.title
  end

  def location
    [city, state, country].compact.join(", ")
  end

  def warmth_label
    %w[cold warm hot champion][warmth] || "unknown"
  end
end

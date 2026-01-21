class Document < ApplicationRecord
  belongs_to :parent, polymorphic: true
  belongs_to :uploaded_by, class_name: "User", optional: true

  validates :name, presence: true
  validates :url, presence: true

  # Required diligence document types for deals
  DILIGENCE_KINDS = %w[
    cap_table
    financials
    investor_deck
    data_room_access
    legal_docs
    term_sheet
    subscription_agreement
    side_letter
    company_formation
    audit_report
  ].freeze

  # Categories for document organization
  DILIGENCE_CATEGORIES = {
    "Financial" => %w[cap_table financials audit_report],
    "Legal" => %w[legal_docs term_sheet subscription_agreement side_letter company_formation],
    "Marketing" => %w[investor_deck data_room_access]
  }.freeze

  scope :confidential, -> { where(is_confidential: true) }
  scope :public_docs, -> { where(is_confidential: false) }
  scope :by_kind, ->(kind) { where(kind: kind) }
  scope :diligence, -> { where(kind: DILIGENCE_KINDS) }
  scope :expiring_soon, -> { where("expires_at <= ?", 30.days.from_now) }
  scope :expired, -> { where("expires_at < ?", Date.current) }
  scope :recent, -> { order(created_at: :desc) }

  def diligence?
    DILIGENCE_KINDS.include?(kind)
  end

  def category
    DILIGENCE_CATEGORIES.find { |_, kinds| kinds.include?(kind) }&.first || "Other"
  end

  def expired?
    expires_at.present? && expires_at < Date.current
  end

  def expiring_soon?
    expires_at.present? && expires_at <= 30.days.from_now && !expired?
  end

  def file_size_mb
    return nil unless file_size_bytes
    (file_size_bytes.to_f / 1_048_576).round(2)
  end

  def file_extension
    return nil unless name
    File.extname(name).delete(".").downcase
  end

  def image?
    %w[jpg jpeg png gif webp svg].include?(file_extension)
  end

  def pdf?
    file_extension == "pdf"
  end

  def spreadsheet?
    %w[xls xlsx csv].include?(file_extension)
  end

  def document?
    %w[doc docx txt rtf].include?(file_extension)
  end
end

class Document < ApplicationRecord
  belongs_to :parent, polymorphic: true
  belongs_to :uploaded_by, class_name: "User", optional: true

  validates :name, presence: true
  validates :url, presence: true

  scope :confidential, -> { where(is_confidential: true) }
  scope :public_docs, -> { where(is_confidential: false) }
  scope :by_kind, ->(kind) { where(kind: kind) }
  scope :expiring_soon, -> { where("expires_at <= ?", 30.days.from_now) }
  scope :expired, -> { where("expires_at < ?", Date.current) }
  scope :recent, -> { order(created_at: :desc) }

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

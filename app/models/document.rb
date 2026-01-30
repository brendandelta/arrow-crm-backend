class Document < ApplicationRecord
  # Associations
  belongs_to :parent, polymorphic: true, optional: true  # Legacy parent relationship
  belongs_to :uploaded_by, class_name: 'User', optional: true

  # New unified linking system
  has_many :document_links, dependent: :destroy

  # Linked entities through document_links
  has_many :linked_deals, through: :document_links, source: :linkable, source_type: 'Deal'
  has_many :linked_blocks, through: :document_links, source: :linkable, source_type: 'Block'
  has_many :linked_interests, through: :document_links, source: :linkable, source_type: 'Interest'
  has_many :linked_organizations, through: :document_links, source: :linkable, source_type: 'Organization'
  has_many :linked_people, through: :document_links, source: :linkable, source_type: 'Person'
  has_many :linked_internal_entities, through: :document_links, source: :linkable, source_type: 'InternalEntity'

  # ActiveStorage attachment
  has_one_attached :file

  # Validations
  validates :name, presence: true

  # New field validations
  CATEGORIES = %w[deal entity tax banking legal compliance marketing research other].freeze
  validates :category, inclusion: { in: CATEGORIES }, allow_blank: true

  STATUSES = %w[draft final executed superseded].freeze
  validates :status, inclusion: { in: STATUSES }, allow_blank: true

  SOURCES = %w[uploaded email generated third_party].freeze
  validates :source, inclusion: { in: SOURCES }, allow_blank: true

  SENSITIVITIES = %w[public internal confidential highly_confidential].freeze
  validates :sensitivity, inclusion: { in: SENSITIVITIES }, allow_blank: true

  # Legacy document types for deals (keeping for backwards compatibility)
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

  DILIGENCE_CATEGORIES = {
    'Financial' => %w[cap_table financials audit_report],
    'Legal' => %w[legal_docs term_sheet subscription_agreement side_letter company_formation],
    'Marketing' => %w[investor_deck data_room_access]
  }.freeze

  # Scopes
  scope :confidential, -> { where(is_confidential: true).or(where(sensitivity: %w[confidential highly_confidential])) }
  scope :public_docs, -> { where(is_confidential: false, sensitivity: %w[public internal]) }
  scope :by_kind, ->(kind) { where(doc_type: kind) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :by_status, ->(status) { where(status: status) }
  scope :diligence, -> { where(doc_type: DILIGENCE_KINDS) }
  scope :expiring_soon, -> { where('expires_at <= ?', 30.days.from_now) }
  scope :expired, -> { where('expires_at < ?', Date.current) }
  scope :recent, -> { order(created_at: :desc) }
  scope :in_version_group, ->(group_id) { where(version_group_id: group_id) }
  scope :final, -> { where(status: 'final') }
  scope :draft, -> { where(status: 'draft') }

  # Search scope
  scope :search, ->(query) {
    where('lower(name) LIKE :q OR lower(title) LIKE :q OR lower(description) LIKE :q', q: "%#{query.downcase}%")
  }

  # Instance methods
  def display_title
    title.presence || name
  end

  def diligence?
    DILIGENCE_KINDS.include?(doc_type)
  end

  def legacy_category
    DILIGENCE_CATEGORIES.find { |_, kinds| kinds.include?(doc_type) }&.first || 'Other'
  end

  def category_label
    category&.titleize || 'Other'
  end

  def status_label
    status&.titleize || 'Unknown'
  end

  def source_label
    case source
    when 'uploaded' then 'Uploaded'
    when 'email' then 'Email'
    when 'generated' then 'Generated'
    when 'third_party' then 'Third Party'
    else 'Unknown'
    end
  end

  def sensitivity_label
    case sensitivity
    when 'public' then 'Public'
    when 'internal' then 'Internal'
    when 'confidential' then 'Confidential'
    when 'highly_confidential' then 'Highly Confidential'
    else 'Internal'
    end
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
    File.extname(name).delete('.').downcase
  end

  def image?
    %w[jpg jpeg png gif webp svg].include?(file_extension)
  end

  def pdf?
    file_extension == 'pdf'
  end

  def spreadsheet?
    %w[xls xlsx csv].include?(file_extension)
  end

  def document?
    %w[doc docx txt rtf].include?(file_extension)
  end

  # Version management
  def version_history
    return [] if version_group_id.blank?
    Document.where(version_group_id: version_group_id).order(version: :desc)
  end

  def latest_version?
    return true if version_group_id.blank?
    version == version_history.maximum(:version)
  end

  def create_new_version(attributes = {})
    new_doc = dup
    new_doc.assign_attributes(attributes)
    new_doc.version = (version || 1) + 1
    new_doc.version_group_id ||= SecureRandom.uuid
    new_doc.status = 'draft'
    new_doc
  end

  # Linking helpers
  def link_to(linkable, relationship: 'general', visibility: 'default', created_by: nil)
    document_links.find_or_create_by!(
      linkable: linkable,
      relationship: relationship
    ) do |link|
      link.visibility = visibility
      link.created_by = created_by
    end
  end

  def unlink_from(linkable, relationship: nil)
    scope = document_links.where(linkable: linkable)
    scope = scope.where(relationship: relationship) if relationship.present?
    scope.destroy_all
  end

  def linked_to?(linkable)
    document_links.where(linkable: linkable).exists?
  end

  def all_linked_entities
    document_links.includes(:linkable).map(&:linkable).compact
  end
end

class InternalEntity < ApplicationRecord
  include EncryptedAttributes

  # Associations
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  has_many :bank_accounts, dependent: :destroy
  has_many :entity_signers, dependent: :destroy
  has_many :signers, through: :entity_signers, source: :person
  has_many :document_links, as: :linkable, dependent: :destroy
  has_many :documents, through: :document_links

  # Bridge to organizations (for migration)
  has_many :organizations, dependent: :nullify

  # Encrypted attributes
  encrypted_attribute :ein, last_count: 4

  # Validations
  validates :name_legal, presence: true
  validates :entity_type, presence: true
  validates :status, presence: true

  # Entity type validation
  ENTITY_TYPES = %w[llc c_corp s_corp lp trust series_llc other].freeze
  validates :entity_type, inclusion: { in: ENTITY_TYPES }

  # Status validation
  STATUSES = %w[active inactive dissolved].freeze
  validates :status, inclusion: { in: STATUSES }

  # Tax classification validation
  TAX_CLASSIFICATIONS = %w[disregarded partnership c_corp s_corp trust other].freeze
  validates :tax_classification, inclusion: { in: TAX_CLASSIFICATIONS }, allow_blank: true

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :dissolved, -> { where(status: 'dissolved') }
  scope :by_type, ->(type) { where(entity_type: type) }
  scope :search, ->(query) {
    where('lower(name_legal) LIKE :q OR lower(name_short) LIKE :q', q: "%#{query.downcase}%")
  }

  # Callbacks
  before_save :set_updated_by

  # Instance methods
  def display_name
    name_short.presence || name_legal
  end

  def full_jurisdiction
    [jurisdiction_state, jurisdiction_country].compact.join(', ')
  end

  def entity_type_label
    case entity_type
    when 'llc' then 'LLC'
    when 'c_corp' then 'C Corporation'
    when 's_corp' then 'S Corporation'
    when 'lp' then 'Limited Partnership'
    when 'trust' then 'Trust'
    when 'series_llc' then 'Series LLC'
    else 'Other'
    end
  end

  def status_label
    status&.titleize || 'Unknown'
  end

  def tax_classification_label
    case tax_classification
    when 'disregarded' then 'Disregarded Entity'
    when 'partnership' then 'Partnership'
    when 'c_corp' then 'C Corporation'
    when 's_corp' then 'S Corporation'
    when 'trust' then 'Trust'
    else tax_classification&.titleize || 'Not Specified'
    end
  end

  def primary_bank_account
    bank_accounts.active.find_by(is_primary: true)
  end

  def active_signers
    entity_signers.active.includes(:person)
  end

  private

  def set_updated_by
    # This should be set by the controller, but ensure it's tracked
    self.updated_at = Time.current
  end
end

class Credential < ApplicationRecord
  include EncryptedAttributes

  # Associations
  belongs_to :vault
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  has_many :credential_fields, dependent: :destroy
  has_many :credential_links, dependent: :destroy

  # Linked entities through credential_links
  has_many :linked_deals, through: :credential_links, source: :linkable, source_type: 'Deal'
  has_many :linked_organizations, through: :credential_links, source: :linkable, source_type: 'Organization'
  has_many :linked_people, through: :credential_links, source: :linkable, source_type: 'Person'
  has_many :linked_internal_entities, through: :credential_links, source: :linkable, source_type: 'InternalEntity'

  # Encrypted attributes
  encrypted_attribute :username, last_count: 4
  encrypted_attribute :email, last_count: 4
  encrypted_attribute :secret, last_count: 4
  encrypted_attribute :notes, last_count: 0  # Notes don't need last4

  # Validations
  validates :title, presence: true
  validates :credential_type, presence: true

  # Credential type validation
  CREDENTIAL_TYPES = %w[
    login
    api_key
    ssh_key
    database
    bank_portal
    cloud_provider
    otp_seed
    recovery_codes
    other
  ].freeze
  validates :credential_type, inclusion: { in: CREDENTIAL_TYPES }

  # Sensitivity validation
  SENSITIVITIES = %w[internal confidential highly_confidential].freeze
  validates :sensitivity, inclusion: { in: SENSITIVITIES }

  # Scopes
  scope :by_type, ->(type) { where(credential_type: type) }
  scope :by_sensitivity, ->(sens) { where(sensitivity: sens) }
  scope :search, ->(query) {
    where('lower(title) LIKE :q OR lower(url) LIKE :q', q: "%#{query.downcase}%")
  }

  # Rotation scopes
  scope :with_rotation_policy, -> { where.not(rotation_interval_days: nil) }
  scope :without_rotation_policy, -> { where(rotation_interval_days: nil) }

  scope :rotation_overdue, -> {
    with_rotation_policy
      .where('secret_last_rotated_at IS NULL OR secret_last_rotated_at < NOW() - (rotation_interval_days || \' days\')::interval')
  }

  scope :rotation_due_soon, -> {
    with_rotation_policy
      .where('secret_last_rotated_at IS NOT NULL')
      .where('secret_last_rotated_at >= NOW() - (rotation_interval_days || \' days\')::interval')
      .where('secret_last_rotated_at < NOW() - ((rotation_interval_days - 7) || \' days\')::interval')
  }

  scope :rotation_ok, -> {
    with_rotation_policy
      .where('secret_last_rotated_at IS NOT NULL')
      .where('secret_last_rotated_at >= NOW() - ((rotation_interval_days - 7) || \' days\')::interval')
  }

  # Instance methods
  def credential_type_label
    case credential_type
    when 'login' then 'Login'
    when 'api_key' then 'API Key'
    when 'ssh_key' then 'SSH Key'
    when 'database' then 'Database'
    when 'bank_portal' then 'Bank Portal'
    when 'cloud_provider' then 'Cloud Provider'
    when 'otp_seed' then 'OTP Seed'
    when 'recovery_codes' then 'Recovery Codes'
    else 'Other'
    end
  end

  def sensitivity_label
    case sensitivity
    when 'internal' then 'Internal'
    when 'confidential' then 'Confidential'
    when 'highly_confidential' then 'Highly Confidential'
    else 'Unknown'
    end
  end

  def rotation_status
    return 'no_policy' unless rotation_interval_days.present?
    return 'overdue' if rotation_overdue?
    return 'due_soon' if rotation_due_soon?
    'ok'
  end

  def rotation_overdue?
    return false unless rotation_interval_days.present?
    return true if secret_last_rotated_at.nil?
    secret_last_rotated_at < rotation_interval_days.days.ago
  end

  def rotation_due_soon?
    return false unless rotation_interval_days.present?
    return false if secret_last_rotated_at.nil?
    return false if rotation_overdue?
    secret_last_rotated_at < (rotation_interval_days - 7).days.ago
  end

  def days_until_rotation
    return nil unless rotation_interval_days.present?
    return 0 if secret_last_rotated_at.nil?
    due_date = secret_last_rotated_at + rotation_interval_days.days
    (due_date.to_date - Date.current).to_i
  end

  def mark_secret_rotated!
    update!(secret_last_rotated_at: Time.current)
  end

  # Linking helpers
  def link_to(linkable, relationship: 'general', created_by: nil)
    credential_links.find_or_create_by!(
      linkable: linkable,
      relationship: relationship
    ) do |link|
      link.created_by = created_by
    end
  end

  def unlink_from(linkable, relationship: nil)
    scope = credential_links.where(linkable: linkable)
    scope = scope.where(relationship: relationship) if relationship.present?
    scope.destroy_all
  end

  def all_linked_entities
    credential_links.includes(:linkable).map(&:linkable).compact
  end
end

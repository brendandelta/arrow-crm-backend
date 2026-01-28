class BankAccount < ApplicationRecord
  include EncryptedAttributes

  # Associations
  belongs_to :internal_entity
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  # Encrypted attributes
  encrypted_attribute :routing_number, last_count: 4
  encrypted_attribute :account_number, last_count: 4

  # SWIFT doesn't need last4 (different format)
  def set_swift(value)
    if value.blank?
      self.swift_ciphertext = nil
    else
      self.swift_ciphertext = Security::Encryption.encrypt(value)
    end
  end

  def swift_decrypted
    Security::Encryption.decrypt(swift_ciphertext)
  end

  def swift_masked
    decrypted = swift_decrypted
    return nil if decrypted.blank?
    "#{decrypted.first(4)}••••"
  end

  # Validations
  validates :internal_entity_id, presence: true
  validates :status, presence: true

  # Account type validation
  ACCOUNT_TYPES = %w[checking savings brokerage trust other].freeze
  validates :account_type, inclusion: { in: ACCOUNT_TYPES }, allow_blank: true

  # Status validation
  STATUSES = %w[active closed].freeze
  validates :status, inclusion: { in: STATUSES }

  # Only one primary active account per entity
  validate :only_one_primary_per_entity, if: -> { is_primary? && status == 'active' }

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :closed, -> { where(status: 'closed') }
  scope :primary, -> { where(is_primary: true) }

  # Callbacks
  before_save :ensure_single_primary

  # Instance methods
  def display_name
    nickname.presence || [bank_name, account_name].compact.join(' - ').presence || "Account #{id}"
  end

  def account_type_label
    case account_type
    when 'checking' then 'Checking'
    when 'savings' then 'Savings'
    when 'brokerage' then 'Brokerage'
    when 'trust' then 'Trust'
    else 'Other'
    end
  end

  def status_label
    status&.titleize || 'Unknown'
  end

  def summary
    parts = []
    parts << bank_name if bank_name.present?
    parts << account_type_label
    parts << "••••#{account_last4}" if account_last4.present?
    parts.join(' · ')
  end

  private

  def only_one_primary_per_entity
    existing = internal_entity.bank_accounts
                              .active
                              .where(is_primary: true)
                              .where.not(id: id)

    if existing.exists?
      errors.add(:is_primary, 'another active primary account already exists for this entity')
    end
  end

  def ensure_single_primary
    # If setting this as primary, unset others
    if is_primary? && is_primary_changed? && status == 'active'
      internal_entity.bank_accounts
                     .active
                     .where(is_primary: true)
                     .where.not(id: id)
                     .update_all(is_primary: false)
    end
  end
end

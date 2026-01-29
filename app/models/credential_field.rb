class CredentialField < ApplicationRecord
  include EncryptedAttributes

  # Associations
  belongs_to :credential

  # Encrypted value
  encrypted_attribute :value, last_count: 4

  # Validations
  validates :label, presence: true
  validates :field_type, presence: true

  # Field type validation
  FIELD_TYPES = %w[text password token pin note].freeze
  validates :field_type, inclusion: { in: FIELD_TYPES }

  # Scopes
  scope :ordered, -> { order(sort_order: :asc, created_at: :asc) }
  scope :secret_fields, -> { where(is_secret: true) }
  scope :non_secret_fields, -> { where(is_secret: false) }

  # Instance methods
  def field_type_label
    case field_type
    when 'text' then 'Text'
    when 'password' then 'Password'
    when 'token' then 'Token'
    when 'pin' then 'PIN'
    when 'note' then 'Note'
    else 'Unknown'
    end
  end

  def should_mask?
    is_secret
  end

  # For display purposes
  def masked_value
    return nil unless value_ciphertext.present?
    return '••••••••' unless value_last4.present?
    "••••#{value_last4}"
  end
end

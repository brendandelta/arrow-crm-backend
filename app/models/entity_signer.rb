class EntitySigner < ApplicationRecord
  # Associations
  belongs_to :internal_entity
  belongs_to :person
  belongs_to :created_by, class_name: 'User', optional: true

  # Validations
  validates :internal_entity_id, presence: true
  validates :person_id, presence: true
  validates :role, presence: true

  # Role validation
  ROLES = %w[manager member officer trustee authorized_signer accountant attorney other].freeze
  validates :role, inclusion: { in: ROLES }

  # Scopes
  scope :active, -> {
    where('effective_from IS NULL OR effective_from <= ?', Date.current)
      .where('effective_to IS NULL OR effective_to >= ?', Date.current)
  }
  scope :expired, -> { where('effective_to < ?', Date.current) }
  scope :future, -> { where('effective_from > ?', Date.current) }
  scope :by_role, ->(role) { where(role: role) }
  scope :managers, -> { where(role: 'manager') }
  scope :officers, -> { where(role: 'officer') }
  scope :authorized_signers, -> { where(role: %w[manager officer authorized_signer]) }

  # Instance methods
  def active?
    (effective_from.nil? || effective_from <= Date.current) &&
      (effective_to.nil? || effective_to >= Date.current)
  end

  def expired?
    effective_to.present? && effective_to < Date.current
  end

  def future?
    effective_from.present? && effective_from > Date.current
  end

  def role_label
    case role
    when 'manager' then 'Manager'
    when 'member' then 'Member'
    when 'officer' then 'Officer'
    when 'trustee' then 'Trustee'
    when 'authorized_signer' then 'Authorized Signer'
    when 'accountant' then 'Accountant'
    when 'attorney' then 'Attorney'
    else 'Other'
    end
  end

  def status_label
    if expired?
      'Expired'
    elsif future?
      'Future'
    else
      'Active'
    end
  end

  def display_name
    "#{person.full_name} (#{role_label})"
  end

  def duration_display
    parts = []
    parts << "From #{effective_from.strftime('%b %Y')}" if effective_from.present?
    parts << "Until #{effective_to.strftime('%b %Y')}" if effective_to.present?
    parts.empty? ? 'Ongoing' : parts.join(' · ')
  end
end

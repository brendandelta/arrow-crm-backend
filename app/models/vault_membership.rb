class VaultMembership < ApplicationRecord
  # Associations
  belongs_to :vault
  belongs_to :user
  belongs_to :created_by, class_name: 'User', optional: true

  # Validations
  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :vault_id, message: 'already has membership in this vault' }

  # Role validation
  ROLES = %w[admin editor revealer viewer].freeze
  validates :role, inclusion: { in: ROLES }

  # Role hierarchy helpers
  def admin?
    role == 'admin'
  end

  def editor?
    role == 'editor'
  end

  def revealer?
    role == 'revealer'
  end

  def viewer?
    role == 'viewer'
  end

  def can_reveal?
    admin? || revealer?
  end

  def can_edit?
    admin? || editor?
  end

  def can_manage_memberships?
    admin?
  end

  def role_label
    role&.titleize || 'Unknown'
  end

  # Role descriptions for UI
  ROLE_DESCRIPTIONS = {
    'admin' => 'Full access including membership management',
    'editor' => 'Can create and update credentials, cannot reveal secrets',
    'revealer' => 'Can view and reveal secrets, cannot edit',
    'viewer' => 'Can view masked credentials only'
  }.freeze

  def role_description
    ROLE_DESCRIPTIONS[role] || 'Unknown role'
  end
end

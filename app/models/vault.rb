class Vault < ApplicationRecord
  # Associations
  belongs_to :created_by, class_name: 'User', optional: true
  has_many :vault_memberships, dependent: :destroy
  has_many :members, through: :vault_memberships, source: :user
  has_many :credentials, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true

  # Scopes
  scope :accessible_by, ->(user) {
    joins(:vault_memberships).where(vault_memberships: { user_id: user.id })
  }

  # Instance methods
  def membership_for(user)
    vault_memberships.find_by(user_id: user.id)
  end

  def role_for(user)
    membership_for(user)&.role
  end

  def admin?(user)
    role_for(user) == 'admin'
  end

  def can_reveal?(user)
    %w[admin revealer].include?(role_for(user))
  end

  def can_edit?(user)
    %w[admin editor].include?(role_for(user))
  end

  def can_view?(user)
    membership_for(user).present?
  end

  # Stats
  def credentials_count
    credentials.count
  end

  def overdue_rotations_count
    credentials.rotation_overdue.count
  end

  def due_soon_rotations_count
    credentials.rotation_due_soon.count
  end
end

class User < ApplicationRecord
  has_many :owned_people, class_name: "Person", foreign_key: :owner_id, dependent: :nullify
  has_many :owned_organizations, class_name: "Organization", foreign_key: :owner_id, dependent: :nullify
  has_many :owned_deals, class_name: "Deal", foreign_key: :owner_id, dependent: :nullify
  has_many :owned_interests, class_name: "Interest", foreign_key: :owner_id, dependent: :nullify
  has_many :meetings, foreign_key: :owner_id, dependent: :nullify
  has_many :notes, foreign_key: :author_id, dependent: :nullify
  has_many :documents, foreign_key: :uploaded_by_id, dependent: :nullify
  has_many :assigned_tasks, class_name: "Task", foreign_key: :assigned_to_id, dependent: :nullify
  has_many :created_tasks, class_name: "Task", foreign_key: :created_by_id, dependent: :nullify
  has_many :security_audit_logs, foreign_key: :actor_user_id, dependent: :nullify

  # Roles
  ROLES = %w[member ops admin].freeze

  validates :email, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :role, inclusion: { in: ROLES }, allow_blank: true

  scope :active, -> { where(is_active: true) }
  scope :admins, -> { where(role: 'admin') }
  scope :ops, -> { where(role: %w[ops admin]) }

  def full_name
    "#{first_name} #{last_name}"
  end

  # RBAC helper methods
  def admin?
    role == 'admin'
  end

  def ops?
    role.in?(%w[ops admin])
  end

  def member?
    role == 'member' || role.blank?
  end

  # Permission checks for sensitive data
  def can_reveal_secrets?
    ops? || admin?
  end

  def can_manage_internal_entities?
    ops? || admin?
  end

  def can_manage_bank_accounts?
    ops? || admin?
  end

  def can_view_confidential_documents?
    ops? || admin?
  end

  def role_label
    case role
    when 'admin' then 'Administrator'
    when 'ops' then 'Operations'
    else 'Member'
    end
  end
end

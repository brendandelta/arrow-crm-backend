class SecurityAuditLog < ApplicationRecord
  # Associations
  belongs_to :actor_user, class_name: 'User'
  belongs_to :auditable, polymorphic: true

  # Validations
  validates :actor_user_id, presence: true
  validates :action, presence: true
  validates :auditable_type, presence: true
  validates :auditable_id, presence: true

  # Action types
  ACTIONS = %w[
    view_decrypted_field
    reveal_secret
    copy_secret
    update_secret
    delete_secret
    permission_change
    access_denied
  ].freeze
  validates :action, inclusion: { in: ACTIONS }

  # Auditable types
  AUDITABLE_TYPES = %w[InternalEntity BankAccount Document User Credential].freeze
  validates :auditable_type, inclusion: { in: AUDITABLE_TYPES }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_actor, ->(user_id) { where(actor_user_id: user_id) }
  scope :by_action, ->(action) { where(action: action) }
  scope :reveals, -> { where(action: %w[reveal_secret view_decrypted_field]) }
  scope :updates, -> { where(action: %w[update_secret delete_secret]) }
  scope :denials, -> { where(action: 'access_denied') }
  scope :for_entity, ->(entity) { where(auditable: entity) }
  scope :today, -> { where('created_at >= ?', Date.current.beginning_of_day) }
  scope :this_week, -> { where('created_at >= ?', 1.week.ago) }
  scope :this_month, -> { where('created_at >= ?', 1.month.ago) }

  # Class methods for logging
  class << self
    def log_reveal(user:, auditable:, field_name:, ip_address: nil, user_agent: nil)
      create!(
        actor_user: user,
        auditable: auditable,
        action: 'reveal_secret',
        metadata: {
          field_name: field_name,
          ip_address: ip_address,
          user_agent: user_agent,
          timestamp: Time.current.iso8601
        }
      )
    end

    def log_view(user:, auditable:, field_name:, ip_address: nil, user_agent: nil)
      create!(
        actor_user: user,
        auditable: auditable,
        action: 'view_decrypted_field',
        metadata: {
          field_name: field_name,
          ip_address: ip_address,
          user_agent: user_agent,
          timestamp: Time.current.iso8601
        }
      )
    end

    def log_update(user:, auditable:, field_name:, ip_address: nil, user_agent: nil)
      create!(
        actor_user: user,
        auditable: auditable,
        action: 'update_secret',
        metadata: {
          field_name: field_name,
          ip_address: ip_address,
          user_agent: user_agent,
          timestamp: Time.current.iso8601
        }
      )
    end

    def log_access_denied(user:, auditable:, action_attempted:, ip_address: nil, user_agent: nil)
      create!(
        actor_user: user,
        auditable: auditable,
        action: 'access_denied',
        metadata: {
          action_attempted: action_attempted,
          ip_address: ip_address,
          user_agent: user_agent,
          timestamp: Time.current.iso8601
        }
      )
    end
  end

  # Instance methods
  def action_label
    case action
    when 'view_decrypted_field' then 'Viewed Decrypted Field'
    when 'reveal_secret' then 'Revealed Secret'
    when 'copy_secret' then 'Copied Secret'
    when 'update_secret' then 'Updated Secret'
    when 'delete_secret' then 'Deleted Secret'
    when 'permission_change' then 'Permission Changed'
    when 'access_denied' then 'Access Denied'
    else action&.titleize || 'Unknown'
    end
  end

  def auditable_label
    case auditable_type
    when 'InternalEntity'
      auditable&.display_name || "Entity ##{auditable_id}"
    when 'BankAccount'
      auditable&.display_name || "Bank Account ##{auditable_id}"
    when 'Document'
      auditable&.display_title || "Document ##{auditable_id}"
    when 'User'
      auditable&.full_name || "User ##{auditable_id}"
    when 'Credential'
      auditable&.title || "Credential ##{auditable_id}"
    else
      "#{auditable_type} ##{auditable_id}"
    end
  end

  def field_name
    metadata['field_name']
  end

  def ip_address
    metadata['ip_address']
  end

  def user_agent
    metadata['user_agent']
  end

  def summary
    "#{actor_user.full_name} #{action_label.downcase} on #{auditable_label}"
  end
end

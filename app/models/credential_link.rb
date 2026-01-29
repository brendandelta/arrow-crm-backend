class CredentialLink < ApplicationRecord
  # Associations
  belongs_to :credential
  belongs_to :linkable, polymorphic: true
  belongs_to :created_by, class_name: 'User', optional: true

  # Validations
  validates :linkable_type, presence: true
  validates :linkable_id, presence: true
  validates :credential_id, uniqueness: {
    scope: [:linkable_type, :linkable_id, :relationship],
    message: 'already linked to this entity with this relationship'
  }

  # Linkable type validation
  LINKABLE_TYPES = %w[Deal Organization Person InternalEntity].freeze
  validates :linkable_type, inclusion: { in: LINKABLE_TYPES }

  # Relationship validation
  RELATIONSHIPS = %w[general primary login admin backup].freeze
  validates :relationship, inclusion: { in: RELATIONSHIPS }, allow_blank: true

  # Scopes
  scope :for_type, ->(type) { where(linkable_type: type) }
  scope :deals, -> { where(linkable_type: 'Deal') }
  scope :organizations, -> { where(linkable_type: 'Organization') }
  scope :people, -> { where(linkable_type: 'Person') }
  scope :internal_entities, -> { where(linkable_type: 'InternalEntity') }

  # Instance methods
  def linkable_label
    case linkable_type
    when 'Deal'
      linkable&.name
    when 'Organization'
      linkable&.name
    when 'Person'
      linkable&.full_name
    when 'InternalEntity'
      linkable&.display_name
    else
      "#{linkable_type} ##{linkable_id}"
    end
  end

  def relationship_label
    case relationship
    when 'general' then 'General'
    when 'primary' then 'Primary'
    when 'login' then 'Login'
    when 'admin' then 'Admin'
    when 'backup' then 'Backup'
    else relationship&.titleize || 'General'
    end
  end
end

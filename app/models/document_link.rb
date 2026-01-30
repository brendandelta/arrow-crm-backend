class DocumentLink < ApplicationRecord
  # Associations
  belongs_to :document
  belongs_to :linkable, polymorphic: true
  belongs_to :created_by, class_name: 'User', optional: true

  # Validations
  validates :document_id, presence: true
  validates :linkable_type, presence: true
  validates :linkable_id, presence: true
  validates :relationship, presence: true
  validates :visibility, presence: true

  # Uniqueness validation
  validates :document_id, uniqueness: {
    scope: [:linkable_type, :linkable_id, :relationship],
    message: 'already linked with this relationship'
  }

  # Linkable type validation
  LINKABLE_TYPES = %w[Deal Block Interest Organization Person InternalEntity].freeze
  validates :linkable_type, inclusion: { in: LINKABLE_TYPES }

  # Relationship types
  RELATIONSHIPS = %w[
    general
    deal_material
    entity_tax
    entity_banking
    entity_governing
    diligence
    compliance
    ops
    legal
    financial
    marketing
    research
  ].freeze
  validates :relationship, inclusion: { in: RELATIONSHIPS }

  # Visibility levels
  VISIBILITIES = %w[default restricted confidential].freeze
  validates :visibility, inclusion: { in: VISIBILITIES }

  # Scopes
  scope :for_deals, -> { where(linkable_type: 'Deal') }
  scope :for_blocks, -> { where(linkable_type: 'Block') }
  scope :for_interests, -> { where(linkable_type: 'Interest') }
  scope :for_organizations, -> { where(linkable_type: 'Organization') }
  scope :for_people, -> { where(linkable_type: 'Person') }
  scope :for_internal_entities, -> { where(linkable_type: 'InternalEntity') }
  scope :by_relationship, ->(rel) { where(relationship: rel) }
  scope :visible, -> { where(visibility: %w[default restricted]) }
  scope :confidential, -> { where(visibility: 'confidential') }

  # Instance methods
  def relationship_label
    relationship&.titleize&.gsub('_', ' ') || 'General'
  end

  def visibility_label
    case visibility
    when 'default' then 'Default'
    when 'restricted' then 'Restricted'
    when 'confidential' then 'Confidential'
    else 'Unknown'
    end
  end

  def linkable_label
    case linkable_type
    when 'Deal'
      linkable&.name || "Deal ##{linkable_id}"
    when 'Block'
      if linkable
        seller_name = linkable.seller&.name || 'Unknown Seller'
        "Block: #{seller_name}"
      else
        "Block ##{linkable_id}"
      end
    when 'Interest'
      if linkable
        investor_name = linkable.investor&.name || 'Unknown Investor'
        "Interest: #{investor_name}"
      else
        "Interest ##{linkable_id}"
      end
    when 'Organization'
      linkable&.name || "Org ##{linkable_id}"
    when 'Person'
      linkable&.full_name || "Person ##{linkable_id}"
    when 'InternalEntity'
      linkable&.display_name || "Entity ##{linkable_id}"
    else
      "#{linkable_type} ##{linkable_id}"
    end
  end
end

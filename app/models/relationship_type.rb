class RelationshipType < ApplicationRecord
  has_many :relationships, dependent: :restrict_with_error

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :active, -> { where(is_active: true) }
  scope :system_types, -> { where(is_system: true) }
  scope :custom_types, -> { where(is_system: false) }
  scope :for_source_type, ->(type) { where(source_type: [type, nil]) }
  scope :for_target_type, ->(type) { where(target_type: [type, nil]) }
  scope :for_pair, ->(source_type, target_type) {
    where(source_type: [source_type, nil])
      .where(target_type: [target_type, nil])
  }
  scope :by_category, ->(category) { where(category: category) }
  scope :ordered, -> { order(:sort_order, :name) }

  # Get the inverse relationship type (for directional relationships)
  def inverse_type
    return self if bidirectional?
    return nil unless inverse_slug.present?

    RelationshipType.find_by(slug: inverse_slug)
  end

  # Check if this type can connect the given entity types
  def valid_for?(source_entity_type, target_entity_type)
    (source_type.nil? || source_type == source_entity_type) &&
      (target_type.nil? || target_type == target_entity_type)
  end
end

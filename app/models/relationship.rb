class Relationship < ApplicationRecord
  belongs_to :relationship_type
  belongs_to :created_by, class_name: "User", optional: true

  # Polymorphic associations
  belongs_to :source, polymorphic: true
  belongs_to :target, polymorphic: true

  validates :source_type, presence: true
  validates :source_id, presence: true
  validates :target_type, presence: true
  validates :target_id, presence: true
  validates :relationship_type_id, presence: true
  validates :strength, numericality: { in: 0..100 }, allow_nil: true

  validate :validate_relationship_type_constraints
  validate :prevent_self_relationship

  scope :active, -> { where(status: "active") }
  scope :historical, -> { where(status: "historical") }
  scope :for_source, ->(entity) { where(source_type: entity.class.name, source_id: entity.id) }
  scope :for_target, ->(entity) { where(target_type: entity.class.name, target_id: entity.id) }
  scope :involving, ->(entity) {
    where(source_type: entity.class.name, source_id: entity.id)
      .or(where(target_type: entity.class.name, target_id: entity.id))
  }
  scope :of_type, ->(relationship_type) { where(relationship_type: relationship_type) }
  scope :with_strength_above, ->(min) { where("strength >= ?", min) }

  # Get the "other" entity in this relationship from the perspective of the given entity
  def other_entity(from_entity)
    if source_type == from_entity.class.name && source_id == from_entity.id
      target
    elsif target_type == from_entity.class.name && target_id == from_entity.id
      source
    else
      nil
    end
  end

  # Get the relationship name from the perspective of the given entity
  def name_from_perspective(from_entity)
    if source_type == from_entity.class.name && source_id == from_entity.id
      relationship_type.name
    elsif target_type == from_entity.class.name && target_id == from_entity.id
      relationship_type.bidirectional? ? relationship_type.name : (relationship_type.inverse_name || relationship_type.name)
    else
      relationship_type.name
    end
  end

  private

  def validate_relationship_type_constraints
    return unless relationship_type.present?

    unless relationship_type.valid_for?(source_type, target_type)
      errors.add(:relationship_type, "is not valid for #{source_type} → #{target_type} relationships")
    end
  end

  def prevent_self_relationship
    if source_type == target_type && source_id == target_id
      errors.add(:base, "An entity cannot have a relationship with itself")
    end
  end
end

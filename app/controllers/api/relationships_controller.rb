class Api::RelationshipsController < ApplicationController
  # GET /api/relationships
  # Params: source_type, source_id, target_type, target_id, entity_type, entity_id
  def index
    relationships = Relationship.includes(:relationship_type)

    # Filter by specific source
    if params[:source_type].present? && params[:source_id].present?
      relationships = relationships.where(source_type: params[:source_type], source_id: params[:source_id])
    end

    # Filter by specific target
    if params[:target_type].present? && params[:target_id].present?
      relationships = relationships.where(target_type: params[:target_type], target_id: params[:target_id])
    end

    # Filter by entity involvement (either source or target)
    if params[:entity_type].present? && params[:entity_id].present?
      entity_type = params[:entity_type]
      entity_id = params[:entity_id]
      relationships = relationships.where(
        "(source_type = ? AND source_id = ?) OR (target_type = ? AND target_id = ?)",
        entity_type, entity_id, entity_type, entity_id
      )
    end

    # Filter by status
    relationships = relationships.where(status: params[:status]) if params[:status].present?

    render json: relationships.map { |r| serialize_relationship(r, params[:entity_type], params[:entity_id]) }
  end

  # GET /api/relationships/:id
  def show
    relationship = Relationship.includes(:relationship_type).find(params[:id])
    render json: serialize_relationship(relationship)
  end

  # POST /api/relationships
  def create
    relationship = Relationship.new(relationship_params)

    if relationship.save
      render json: {
        id: relationship.id,
        success: true
      }, status: :created
    else
      render json: { errors: relationship.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/relationships/:id
  def update
    relationship = Relationship.find(params[:id])

    if relationship.update(relationship_params)
      render json: { id: relationship.id, success: true }
    else
      render json: { errors: relationship.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/relationships/:id
  def destroy
    relationship = Relationship.find(params[:id])
    relationship.destroy
    render json: { success: true }
  end

  private

  def relationship_params
    {
      source_type: params[:sourceType],
      source_id: params[:sourceId],
      target_type: params[:targetType],
      target_id: params[:targetId],
      relationship_type_id: params[:relationshipTypeId],
      strength: params[:strength],
      status: params[:status] || "active",
      started_at: params[:startedAt],
      ended_at: params[:endedAt],
      notes: params[:notes],
      metadata: params[:metadata] || {}
    }.compact
  end

  def serialize_relationship(relationship, from_entity_type = nil, from_entity_id = nil)
    rt = relationship.relationship_type

    # Determine perspective-aware name
    if from_entity_type.present? && from_entity_id.present?
      is_source = relationship.source_type == from_entity_type && relationship.source_id == from_entity_id.to_i
      relationship_name = is_source ? rt.name : (rt.bidirectional ? rt.name : (rt.inverse_name || rt.name))
      other_type = is_source ? relationship.target_type : relationship.source_type
      other_id = is_source ? relationship.target_id : relationship.source_id
    else
      relationship_name = rt.name
      other_type = nil
      other_id = nil
    end

    # Get entity names for display
    source_name = get_entity_name(relationship.source_type, relationship.source_id)
    target_name = get_entity_name(relationship.target_type, relationship.target_id)

    {
      id: relationship.id,
      sourceType: relationship.source_type,
      sourceId: relationship.source_id,
      sourceName: source_name,
      targetType: relationship.target_type,
      targetId: relationship.target_id,
      targetName: target_name,
      relationshipType: {
        id: rt.id,
        name: rt.name,
        slug: rt.slug,
        color: rt.color,
        icon: rt.icon,
        bidirectional: rt.bidirectional,
        inverseName: rt.inverse_name
      },
      relationshipName: relationship_name,
      otherEntityType: other_type,
      otherEntityId: other_id,
      strength: relationship.strength,
      status: relationship.status,
      startedAt: relationship.started_at,
      endedAt: relationship.ended_at,
      notes: relationship.notes,
      metadata: relationship.metadata,
      createdAt: relationship.created_at
    }
  end

  def get_entity_name(entity_type, entity_id)
    case entity_type
    when "Person"
      person = Person.find_by(id: entity_id)
      person ? "#{person.first_name} #{person.last_name}" : nil
    when "Organization"
      org = Organization.find_by(id: entity_id)
      org&.name
    when "Deal"
      deal = Deal.find_by(id: entity_id)
      deal&.name
    else
      nil
    end
  end
end

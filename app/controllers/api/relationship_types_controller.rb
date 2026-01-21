class Api::RelationshipTypesController < ApplicationController
  def index
    types = RelationshipType.active.ordered

    # Filter by entity pair if specified
    if params[:source_type].present? && params[:target_type].present?
      types = types.for_pair(params[:source_type], params[:target_type])
    elsif params[:source_type].present?
      types = types.for_source_type(params[:source_type])
    elsif params[:target_type].present?
      types = types.for_target_type(params[:target_type])
    end

    # Filter by category if specified
    types = types.by_category(params[:category]) if params[:category].present?

    render json: types.map { |rt|
      {
        id: rt.id,
        name: rt.name,
        slug: rt.slug,
        sourceType: rt.source_type,
        targetType: rt.target_type,
        category: rt.category,
        bidirectional: rt.bidirectional,
        inverseName: rt.inverse_name,
        inverseSlug: rt.inverse_slug,
        description: rt.description,
        color: rt.color,
        icon: rt.icon,
        isSystem: rt.is_system
      }
    }
  end

  def create
    type = RelationshipType.new(relationship_type_params)
    type.is_system = false  # User-created types are not system types

    if type.save
      render json: {
        id: type.id,
        name: type.name,
        slug: type.slug,
        success: true
      }, status: :created
    else
      render json: { errors: type.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def relationship_type_params
    params.permit(
      :name, :slug, :source_type, :target_type, :category,
      :bidirectional, :inverse_name, :inverse_slug, :description,
      :color, :icon, :sort_order
    ).tap do |p|
      # Convert camelCase to snake_case
      p[:source_type] = params[:sourceType] if params[:sourceType].present?
      p[:target_type] = params[:targetType] if params[:targetType].present?
      p[:inverse_name] = params[:inverseName] if params[:inverseName].present?
      p[:inverse_slug] = params[:inverseSlug] if params[:inverseSlug].present?
      p[:sort_order] = params[:sortOrder] if params[:sortOrder].present?
    end
  end
end

class Api::EdgesController < ApplicationController
  def index
    edges = if params[:deal_id]
              Edge.where(deal_id: params[:deal_id])
            elsif params[:person_id]
              Edge.joins(:edge_people).where(edge_people: { person_id: params[:person_id] })
            else
              Edge.all
            end

    # Apply filters
    edges = edges.by_type(params[:edge_type]) if params[:edge_type].present?
    edges = edges.high_confidence if params[:high_confidence] == "true"
    edges = edges.fresh if params[:fresh] == "true"

    # Eager load associations
    edges = edges.includes(:related_person, :related_org, :created_by, :edge_people, :people)

    # Default ordering by composite score (confidence * timeliness)
    edges = edges.by_score.limit(100)

    render json: edges.map { |e| edge_json(e) }
  end

  def show
    edge = Edge.includes(:related_person, :related_org, :created_by, :edge_people, :people).find(params[:id])
    render json: edge_json(edge)
  end

  def create
    edge = Edge.new(edge_params)

    if edge.save
      # Handle people associations
      sync_edge_people(edge)
      render json: edge_json(edge.reload), status: :created
    else
      render json: { errors: edge.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    edge = Edge.find(params[:id])

    if edge.update(edge_params)
      # Handle people associations
      sync_edge_people(edge)
      render json: edge_json(edge.reload)
    else
      render json: { errors: edge.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    edge = Edge.find(params[:id])
    edge.destroy
    render json: { success: true }
  end

  private

  def edge_params
    params.permit(
      :deal_id,
      :title,
      :edge_type,
      :confidence,
      :timeliness,
      :notes,
      :related_person_id,
      :related_org_id,
      :created_by_id
    )
  end

  def sync_edge_people(edge)
    # Expect params[:people] as array of { person_id:, role:, context: }
    return unless params[:people].is_a?(Array)

    # Clear existing and rebuild
    edge.edge_people.destroy_all

    params[:people].each do |person_data|
      next unless person_data[:person_id].present?

      edge.edge_people.create!(
        person_id: person_data[:person_id],
        role: person_data[:role],
        context: person_data[:context]
      )
    end
  end

  def edge_json(edge)
    {
      id: edge.id,
      dealId: edge.deal_id,
      title: edge.title,
      edgeType: edge.edge_type,
      confidence: edge.confidence,
      confidenceLabel: edge.confidence_label,
      timeliness: edge.timeliness,
      timelinessLabel: edge.timeliness_label,
      notes: edge.notes,
      score: edge.score,
      relatedPersonId: edge.related_person_id,
      relatedPerson: edge.related_person ? {
        id: edge.related_person.id,
        firstName: edge.related_person.first_name,
        lastName: edge.related_person.last_name
      } : nil,
      relatedOrgId: edge.related_org_id,
      relatedOrg: edge.related_org ? {
        id: edge.related_org.id,
        name: edge.related_org.name
      } : nil,
      # People linked to this edge (with roles)
      people: edge.edge_people.includes(:person).map { |ep|
        {
          id: ep.person.id,
          firstName: ep.person.first_name,
          lastName: ep.person.last_name,
          title: ep.person.current_title,
          organization: ep.person.current_org&.name,
          role: ep.role,
          context: ep.context
        }
      },
      createdBy: edge.created_by ? {
        id: edge.created_by.id,
        firstName: edge.created_by.first_name,
        lastName: edge.created_by.last_name
      } : nil,
      createdAt: edge.created_at,
      updatedAt: edge.updated_at
    }
  end
end

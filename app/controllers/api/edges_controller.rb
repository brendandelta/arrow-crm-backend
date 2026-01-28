class Api::EdgesController < ApplicationController
  def index
    edges = if params[:deal_id]
              Edge.where(deal_id: params[:deal_id])
            else
              Edge.all
            end

    # Apply filters
    edges = edges.by_type(params[:edge_type]) if params[:edge_type].present?
    edges = edges.high_confidence if params[:high_confidence] == "true"
    edges = edges.fresh if params[:fresh] == "true"

    # Default ordering by composite score (confidence * timeliness)
    edges = edges.by_score.limit(100)

    render json: edges.map { |e| edge_json(e) }
  end

  def show
    edge = Edge.find(params[:id])
    render json: edge_json(edge)
  end

  def create
    edge = Edge.new(edge_params)

    if edge.save
      render json: edge_json(edge), status: :created
    else
      render json: { errors: edge.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    edge = Edge.find(params[:id])

    if edge.update(edge_params)
      render json: edge_json(edge)
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

class Api::AdvantagesController < ApplicationController
  def index
    advantages = if params[:deal_id]
                   Advantage.where(deal_id: params[:deal_id]).recent
                 else
                   Advantage.recent.limit(100)
                 end

    render json: advantages.map { |a| advantage_json(a) }
  end

  def show
    advantage = Advantage.find(params[:id])
    render json: advantage_json(advantage)
  end

  def create
    advantage = Advantage.new(advantage_params)

    if advantage.save
      render json: { id: advantage.id, success: true }, status: :created
    else
      render json: { errors: advantage.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    advantage = Advantage.find(params[:id])

    if advantage.update(advantage_params)
      render json: { id: advantage.id, success: true }
    else
      render json: { errors: advantage.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    advantage = Advantage.find(params[:id])
    advantage.destroy
    render json: { success: true }
  end

  private

  def advantage_params
    params.permit(:deal_id, :kind, :title, :description, :confidence, :timeliness, :source)
  end

  def advantage_json(advantage)
    {
      id: advantage.id,
      dealId: advantage.deal_id,
      kind: advantage.kind,
      title: advantage.title,
      description: advantage.description,
      confidence: advantage.confidence,
      confidenceLabel: advantage.confidence_label,
      timeliness: advantage.timeliness,
      timelinessLabel: advantage.timeliness_label,
      source: advantage.source,
      createdAt: advantage.created_at,
      updatedAt: advantage.updated_at
    }
  end
end

class Api::EntitySignersController < ApplicationController
  before_action :set_entity_signer, only: [:show, :update, :destroy]
  before_action :set_internal_entity, only: [:create]

  def show
    render json: entity_signer_json(@entity_signer)
  end

  def create
    @entity_signer = @internal_entity.entity_signers.new(entity_signer_params)
    @entity_signer.created_by = current_user

    if @entity_signer.save
      render json: entity_signer_json(@entity_signer), status: :created
    else
      render json: { errors: @entity_signer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @entity_signer.update(entity_signer_params)
      render json: entity_signer_json(@entity_signer)
    else
      render json: { errors: @entity_signer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @entity_signer.destroy
    render json: { success: true }
  end

  private

  def set_entity_signer
    @entity_signer = EntitySigner.find(params[:id])
  end

  def set_internal_entity
    @internal_entity = InternalEntity.find(params[:internal_entity_id])
  end

  def entity_signer_params
    params.permit(
      :person_id,
      :role,
      :effective_from,
      :effective_to,
      metadata: {}
    )
  end

  def entity_signer_json(signer)
    {
      id: signer.id,
      internalEntityId: signer.internal_entity_id,
      personId: signer.person_id,
      person: {
        id: signer.person.id,
        firstName: signer.person.first_name,
        lastName: signer.person.last_name,
        fullName: signer.person.full_name,
        title: signer.person.current_title,
        organization: signer.person.current_org&.name
      },
      role: signer.role,
      roleLabel: signer.role_label,
      effectiveFrom: signer.effective_from,
      effectiveTo: signer.effective_to,
      isActive: signer.active?,
      isExpired: signer.expired?,
      isFuture: signer.future?,
      statusLabel: signer.status_label,
      durationDisplay: signer.duration_display,
      metadata: signer.metadata,
      createdAt: signer.created_at,
      updatedAt: signer.updated_at
    }
  end

  def current_user
    @current_user ||= begin
      user_id = request.headers['X-User-Id'] || params[:user_id]
      User.find_by(id: user_id) if user_id.present?
    end
  end
end

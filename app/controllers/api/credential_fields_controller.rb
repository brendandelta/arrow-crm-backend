class Api::CredentialFieldsController < ApplicationController
  before_action :require_current_user
  before_action :set_credential, only: [:create]
  before_action :set_field, only: [:update, :destroy]
  before_action :authorize_edit!

  # POST /api/credentials/:credential_id/fields
  def create
    @field = @credential.credential_fields.new(field_params)

    # Handle encrypted value
    if params[:value].present?
      @field.set_value(params[:value])
    end

    if @field.save
      log_field_update('create')
      render json: field_json(@field), status: :created
    else
      render json: { errors: @field.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/credential_fields/:id
  def update
    # Handle encrypted value update
    if params[:value].present?
      @field.set_value(params[:value])
      log_field_update('update')
    end

    if @field.update(field_params)
      render json: field_json(@field)
    else
      render json: { errors: @field.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/credential_fields/:id
  def destroy
    @field.destroy
    render json: { success: true }
  end

  private

  def set_credential
    @credential = Credential.find(params[:credential_id])
    @vault = @credential.vault
  end

  def set_field
    @field = CredentialField.find(params[:id])
    @credential = @field.credential
    @vault = @credential.vault
  end

  def authorize_edit!
    unless @vault.can_edit?(current_user)
      render json: { error: 'Edit access required' }, status: :forbidden
    end
  end

  def log_field_update(action_type)
    return unless @field.is_secret

    SecurityAuditLog.create!(
      actor_user_id: current_user.id,
      action: 'update_secret',
      auditable_type: 'Credential',
      auditable_id: @credential.id,
      metadata: {
        vault_id: @vault.id,
        credential_title: @credential.title,
        field_label: @field.label,
        field_action: action_type,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }
    )
  end

  def field_params
    params.permit(:label, :field_type, :is_secret, :sort_order)
  end

  def field_json(field)
    {
      id: field.id,
      credentialId: field.credential_id,
      label: field.label,
      fieldType: field.field_type,
      fieldTypeLabel: field.field_type_label,
      isSecret: field.is_secret,
      valueMasked: field.should_mask? ? field.masked_value : field.value_decrypted,
      valuePresent: field.value_ciphertext.present?,
      sortOrder: field.sort_order,
      createdAt: field.created_at,
      updatedAt: field.updated_at
    }
  end

  def require_current_user
    unless current_user
      render json: { error: 'Authentication required' }, status: :unauthorized
    end
  end

  def current_user
    @current_user ||= begin
      user_id = request.headers['X-User-Id'] || params[:user_id]
      User.find_by(id: user_id) if user_id.present?
    end
  end
end

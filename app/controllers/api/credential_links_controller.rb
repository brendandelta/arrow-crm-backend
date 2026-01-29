class Api::CredentialLinksController < ApplicationController
  before_action :require_current_user
  before_action :set_credential, only: [:create]
  before_action :set_link, only: [:destroy]
  before_action :authorize_edit!

  # POST /api/credentials/:credential_id/links
  def create
    @link = @credential.credential_links.new(link_params)
    @link.created_by = current_user

    if @link.save
      render json: link_json(@link), status: :created
    else
      render json: { errors: @link.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/credential_links/:id
  def destroy
    @link.destroy
    render json: { success: true }
  end

  private

  def set_credential
    @credential = Credential.find(params[:credential_id])
    @vault = @credential.vault
  end

  def set_link
    @link = CredentialLink.find(params[:id])
    @credential = @link.credential
    @vault = @credential.vault
  end

  def authorize_edit!
    unless @vault.can_edit?(current_user)
      render json: { error: 'Edit access required' }, status: :forbidden
    end
  end

  def link_params
    params.permit(:linkable_type, :linkable_id, :relationship)
  end

  def link_json(link)
    {
      id: link.id,
      credentialId: link.credential_id,
      linkableType: link.linkable_type,
      linkableId: link.linkable_id,
      label: link.linkable_label,
      relationship: link.relationship,
      relationshipLabel: link.relationship_label,
      createdBy: link.created_by ? {
        id: link.created_by.id,
        name: link.created_by.full_name
      } : nil,
      createdAt: link.created_at
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

class Api::VaultMembershipsController < ApplicationController
  before_action :require_current_user
  before_action :set_vault, only: [:index, :create]
  before_action :set_membership, only: [:update, :destroy]
  before_action :authorize_vault_admin!, only: [:index, :create]
  before_action :authorize_membership_admin!, only: [:update, :destroy]

  # GET /api/vaults/:vault_id/memberships
  def index
    memberships = @vault.vault_memberships.includes(:user, :created_by)

    render json: memberships.map { |m| membership_json(m) }
  end

  # POST /api/vaults/:vault_id/memberships
  def create
    @membership = @vault.vault_memberships.new(membership_params)
    @membership.created_by = current_user

    if @membership.save
      render json: membership_json(@membership), status: :created
    else
      render json: { errors: @membership.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/vault_memberships/:id
  def update
    if @membership.update(membership_params.except(:user_id))
      render json: membership_json(@membership)
    else
      render json: { errors: @membership.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/vault_memberships/:id
  def destroy
    # Prevent removing the last admin
    if @membership.admin? && @membership.vault.vault_memberships.where(role: 'admin').count == 1
      return render json: { error: 'Cannot remove the last admin' }, status: :unprocessable_entity
    end

    @membership.destroy
    render json: { success: true }
  end

  private

  def set_vault
    @vault = Vault.find(params[:vault_id])
  end

  def set_membership
    @membership = VaultMembership.find(params[:id])
    @vault = @membership.vault
  end

  def authorize_vault_admin!
    unless @vault.admin?(current_user)
      render json: { error: 'Admin access required' }, status: :forbidden
    end
  end

  def authorize_membership_admin!
    unless @vault.admin?(current_user)
      render json: { error: 'Admin access required' }, status: :forbidden
    end
  end

  def membership_params
    params.permit(:user_id, :role)
  end

  def membership_json(membership)
    {
      id: membership.id,
      vaultId: membership.vault_id,
      userId: membership.user_id,
      user: {
        id: membership.user.id,
        name: membership.user.full_name,
        email: membership.user.email
      },
      role: membership.role,
      roleLabel: membership.role_label,
      roleDescription: membership.role_description,
      canReveal: membership.can_reveal?,
      canEdit: membership.can_edit?,
      canManageMemberships: membership.can_manage_memberships?,
      createdBy: membership.created_by ? {
        id: membership.created_by.id,
        name: membership.created_by.full_name
      } : nil,
      createdAt: membership.created_at,
      updatedAt: membership.updated_at
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

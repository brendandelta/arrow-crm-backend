class Api::VaultsController < ApplicationController
  before_action :require_current_user
  before_action :set_vault, only: [:show, :update, :destroy, :rotation]
  before_action :authorize_vault_access!, only: [:show, :rotation]
  before_action :authorize_vault_admin!, only: [:update, :destroy]

  # GET /api/vaults
  def index
    vaults = Vault.accessible_by(current_user).includes(:vault_memberships)

    render json: vaults.map { |vault| vault_summary_json(vault) }
  end

  # GET /api/vaults/:id
  def show
    render json: vault_detail_json(@vault)
  end

  # POST /api/vaults
  def create
    # Only system admins can create vaults (or implement your own logic)
    unless current_user&.admin?
      return render json: { error: 'Only administrators can create vaults' }, status: :forbidden
    end

    @vault = Vault.new(vault_params)
    @vault.created_by = current_user

    if @vault.save
      # Auto-add creator as admin
      @vault.vault_memberships.create!(
        user: current_user,
        role: 'admin',
        created_by: current_user
      )
      render json: vault_detail_json(@vault), status: :created
    else
      render json: { errors: @vault.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/vaults/:id
  def update
    if @vault.update(vault_params)
      render json: vault_detail_json(@vault)
    else
      render json: { errors: @vault.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/vaults/:id
  def destroy
    @vault.destroy
    render json: { success: true }
  end

  # GET /api/vaults/:id/rotation
  def rotation
    overdue = @vault.credentials.rotation_overdue.includes(:credential_links)
    due_soon = @vault.credentials.rotation_due_soon.includes(:credential_links)
    no_policy = @vault.credentials.without_rotation_policy.includes(:credential_links)

    render json: {
      overdue: overdue.map { |c| credential_summary_json(c) },
      dueSoon: due_soon.map { |c| credential_summary_json(c) },
      noPolicy: no_policy.map { |c| credential_summary_json(c) }
    }
  end

  private

  def set_vault
    @vault = Vault.find(params[:id])
  end

  def authorize_vault_access!
    unless @vault.can_view?(current_user)
      render json: { error: 'Access denied' }, status: :forbidden
    end
  end

  def authorize_vault_admin!
    unless @vault.admin?(current_user)
      render json: { error: 'Admin access required' }, status: :forbidden
    end
  end

  def vault_params
    params.permit(:name, :description, metadata: {})
  end

  def vault_summary_json(vault)
    membership = vault.membership_for(current_user)
    {
      id: vault.id,
      name: vault.name,
      description: vault.description,
      role: membership&.role,
      roleLabel: membership&.role_label,
      credentialsCount: vault.credentials_count,
      overdueRotationsCount: vault.overdue_rotations_count,
      dueSoonRotationsCount: vault.due_soon_rotations_count,
      createdAt: vault.created_at,
      updatedAt: vault.updated_at
    }
  end

  def vault_detail_json(vault)
    membership = vault.membership_for(current_user)
    {
      id: vault.id,
      name: vault.name,
      description: vault.description,
      metadata: vault.metadata,
      role: membership&.role,
      roleLabel: membership&.role_label,
      canReveal: membership&.can_reveal?,
      canEdit: membership&.can_edit?,
      canManageMemberships: membership&.can_manage_memberships?,
      credentialsCount: vault.credentials_count,
      overdueRotationsCount: vault.overdue_rotations_count,
      dueSoonRotationsCount: vault.due_soon_rotations_count,
      createdBy: vault.created_by ? {
        id: vault.created_by.id,
        name: vault.created_by.full_name
      } : nil,
      createdAt: vault.created_at,
      updatedAt: vault.updated_at
    }
  end

  def credential_summary_json(credential)
    {
      id: credential.id,
      title: credential.title,
      credentialType: credential.credential_type,
      credentialTypeLabel: credential.credential_type_label,
      url: credential.url,
      sensitivity: credential.sensitivity,
      sensitivityLabel: credential.sensitivity_label,
      rotationStatus: credential.rotation_status,
      rotationIntervalDays: credential.rotation_interval_days,
      daysUntilRotation: credential.days_until_rotation,
      secretLastRotatedAt: credential.secret_last_rotated_at,
      linksCount: credential.credential_links.count,
      updatedAt: credential.updated_at
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

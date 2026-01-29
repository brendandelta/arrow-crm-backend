class Api::CredentialsController < ApplicationController
  before_action :require_current_user
  before_action :set_vault, only: [:index, :create]
  before_action :set_credential, only: [:show, :update, :destroy, :reveal, :copy]
  before_action :authorize_vault_access!, only: [:index, :create]
  before_action :authorize_credential_access!, only: [:show]
  before_action :authorize_credential_edit!, only: [:update, :destroy]
  before_action :authorize_credential_reveal!, only: [:reveal, :copy]

  # GET /api/vaults/:vault_id/credentials
  def index
    credentials = @vault.credentials.includes(:credential_links, :credential_fields)

    # Search
    if params[:q].present?
      credentials = credentials.search(params[:q])
    end

    # Filter by type
    if params[:type].present?
      credentials = credentials.by_type(params[:type])
    end

    # Filter by sensitivity
    if params[:sensitivity].present?
      credentials = credentials.by_sensitivity(params[:sensitivity])
    end

    # Filter by rotation status
    case params[:rotation_status]
    when 'overdue'
      credentials = credentials.rotation_overdue
    when 'due_soon'
      credentials = credentials.rotation_due_soon
    when 'ok'
      credentials = credentials.rotation_ok
    when 'no_policy'
      credentials = credentials.without_rotation_policy
    end

    # Filter by linked entity
    if params[:linkable_type].present? && params[:linkable_id].present?
      credentials = credentials.joins(:credential_links)
                               .where(credential_links: {
                                 linkable_type: params[:linkable_type],
                                 linkable_id: params[:linkable_id]
                               })
    end

    credentials = credentials.order(updated_at: :desc)

    render json: credentials.map { |c| credential_summary_json(c) }
  end

  # GET /api/credentials/:id
  def show
    render json: credential_detail_json(@credential)
  end

  # POST /api/vaults/:vault_id/credentials
  def create
    @credential = @vault.credentials.new(credential_params)
    @credential.created_by = current_user
    @credential.updated_by = current_user

    # Handle encrypted fields
    set_encrypted_fields(@credential)

    if @credential.save
      # Create links if provided
      create_credential_links(@credential)

      # Create custom fields if provided
      create_credential_fields(@credential)

      render json: credential_detail_json(@credential), status: :created
    else
      render json: { errors: @credential.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/credentials/:id
  def update
    @credential.updated_by = current_user

    # Track if secret is being updated
    secret_updated = params[:secret].present?

    # Handle encrypted fields
    set_encrypted_fields(@credential)

    if @credential.update(credential_params)
      # Mark secret as rotated if it was updated
      if secret_updated
        @credential.mark_secret_rotated!
        log_secret_update('secret')
      end

      render json: credential_detail_json(@credential)
    else
      render json: { errors: @credential.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/credentials/:id
  def destroy
    @credential.destroy
    render json: { success: true }
  end

  # POST /api/credentials/:id/reveal
  # Returns plaintext secret + secret fields; always logged
  def reveal
    # Log the reveal action
    SecurityAuditLog.create!(
      actor_user_id: current_user.id,
      action: 'reveal_secret',
      auditable_type: 'Credential',
      auditable_id: @credential.id,
      metadata: {
        vault_id: @credential.vault_id,
        credential_title: @credential.title,
        client_context: params[:context],
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }
    )

    # Build response with plaintext values
    response = {
      id: @credential.id,
      username: @credential.username_decrypted,
      email: @credential.email_decrypted,
      secret: @credential.secret_decrypted,
      notes: @credential.notes_decrypted,
      fields: @credential.credential_fields.ordered.map { |f|
        {
          id: f.id,
          label: f.label,
          fieldType: f.field_type,
          isSecret: f.is_secret,
          value: f.is_secret ? f.value_decrypted : f.value_decrypted
        }
      }
    }

    render json: response
  end

  # POST /api/credentials/:id/copy
  # No secret returned; only logs the copy action
  def copy
    field_label = params[:field] || 'secret'

    # Log the copy action
    SecurityAuditLog.create!(
      actor_user_id: current_user.id,
      action: 'copy_secret',
      auditable_type: 'Credential',
      auditable_id: @credential.id,
      metadata: {
        vault_id: @credential.vault_id,
        credential_title: @credential.title,
        field_copied: field_label,
        client_context: params[:context],
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }
    )

    render json: { success: true, logged: true }
  end

  private

  def set_vault
    @vault = Vault.find(params[:vault_id])
  end

  def set_credential
    @credential = Credential.find(params[:id])
    @vault = @credential.vault
  end

  def authorize_vault_access!
    unless @vault.can_view?(current_user)
      render json: { error: 'Access denied' }, status: :forbidden
    end
  end

  def authorize_credential_access!
    unless @vault.can_view?(current_user)
      render json: { error: 'Access denied' }, status: :forbidden
    end
  end

  def authorize_credential_edit!
    unless @vault.can_edit?(current_user)
      render json: { error: 'Edit access required' }, status: :forbidden
    end
  end

  def authorize_credential_reveal!
    unless @vault.can_reveal?(current_user)
      log_access_denied('reveal_secret')
      render json: { error: 'Reveal access required' }, status: :forbidden
    end
  end

  def log_access_denied(action)
    SecurityAuditLog.create!(
      actor_user_id: current_user&.id,
      action: 'access_denied',
      auditable_type: 'Credential',
      auditable_id: @credential&.id,
      metadata: {
        vault_id: @credential&.vault_id,
        action_attempted: action,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }
    )
  end

  def log_secret_update(field_name)
    SecurityAuditLog.create!(
      actor_user_id: current_user.id,
      action: 'update_secret',
      auditable_type: 'Credential',
      auditable_id: @credential.id,
      metadata: {
        vault_id: @credential.vault_id,
        credential_title: @credential.title,
        field_updated: field_name,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }
    )
  end

  def credential_params
    params.permit(
      :title,
      :credential_type,
      :url,
      :sensitivity,
      :rotation_interval_days,
      metadata: {}
    )
  end

  def set_encrypted_fields(credential)
    if params[:username].present?
      credential.set_username(params[:username])
    end

    if params[:email].present?
      credential.set_email(params[:email])
    end

    if params[:secret].present?
      credential.set_secret(params[:secret])
    end

    if params[:notes].present?
      credential.set_notes(params[:notes])
    end
  end

  def create_credential_links(credential)
    return unless params[:links].is_a?(Array)

    params[:links].each do |link_params|
      next unless link_params[:linkable_type].present? && link_params[:linkable_id].present?

      credential.credential_links.create!(
        linkable_type: link_params[:linkable_type],
        linkable_id: link_params[:linkable_id],
        relationship: link_params[:relationship] || 'general',
        created_by: current_user
      )
    end
  end

  def create_credential_fields(credential)
    return unless params[:fields].is_a?(Array)

    params[:fields].each_with_index do |field_params, index|
      next unless field_params[:label].present?

      field = credential.credential_fields.new(
        label: field_params[:label],
        field_type: field_params[:field_type] || 'text',
        is_secret: field_params[:is_secret] != false,
        sort_order: field_params[:sort_order] || index
      )
      field.set_value(field_params[:value]) if field_params[:value].present?
      field.save!
    end
  end

  def credential_summary_json(credential)
    membership = @vault.membership_for(current_user)
    {
      id: credential.id,
      vaultId: credential.vault_id,
      title: credential.title,
      credentialType: credential.credential_type,
      credentialTypeLabel: credential.credential_type_label,
      url: credential.url,
      # Always masked in list view
      usernameMasked: credential.username_masked,
      emailMasked: credential.email_masked,
      secretMasked: credential.secret_masked,
      sensitivity: credential.sensitivity,
      sensitivityLabel: credential.sensitivity_label,
      rotationStatus: credential.rotation_status,
      rotationIntervalDays: credential.rotation_interval_days,
      daysUntilRotation: credential.days_until_rotation,
      secretLastRotatedAt: credential.secret_last_rotated_at,
      links: credential.credential_links.includes(:linkable).map { |link|
        {
          id: link.id,
          linkableType: link.linkable_type,
          linkableId: link.linkable_id,
          label: link.linkable_label,
          relationship: link.relationship
        }
      },
      canReveal: membership&.can_reveal?,
      canEdit: membership&.can_edit?,
      updatedAt: credential.updated_at,
      createdAt: credential.created_at
    }
  end

  def credential_detail_json(credential)
    membership = @vault.membership_for(current_user)
    {
      id: credential.id,
      vaultId: credential.vault_id,
      title: credential.title,
      credentialType: credential.credential_type,
      credentialTypeLabel: credential.credential_type_label,
      url: credential.url,
      # Always masked - use reveal endpoint for plaintext
      usernameMasked: credential.username_masked,
      usernamePresent: credential.username_present?,
      emailMasked: credential.email_masked,
      emailPresent: credential.email_present?,
      secretMasked: credential.secret_masked,
      secretPresent: credential.secret_present?,
      notesMasked: credential.notes_present? ? '••••••••' : nil,
      notesPresent: credential.notes_present?,
      sensitivity: credential.sensitivity,
      sensitivityLabel: credential.sensitivity_label,
      rotationStatus: credential.rotation_status,
      rotationIntervalDays: credential.rotation_interval_days,
      daysUntilRotation: credential.days_until_rotation,
      secretLastRotatedAt: credential.secret_last_rotated_at,
      metadata: credential.metadata,
      fields: credential.credential_fields.ordered.map { |f|
        {
          id: f.id,
          label: f.label,
          fieldType: f.field_type,
          fieldTypeLabel: f.field_type_label,
          isSecret: f.is_secret,
          # Masked or plaintext depending on isSecret
          valueMasked: f.should_mask? ? f.masked_value : f.value_decrypted,
          valuePresent: f.value_ciphertext.present?,
          sortOrder: f.sort_order
        }
      },
      links: credential.credential_links.includes(:linkable).map { |link|
        {
          id: link.id,
          linkableType: link.linkable_type,
          linkableId: link.linkable_id,
          label: link.linkable_label,
          relationship: link.relationship,
          relationshipLabel: link.relationship_label
        }
      },
      canReveal: membership&.can_reveal?,
      canEdit: membership&.can_edit?,
      createdBy: credential.created_by ? {
        id: credential.created_by.id,
        name: credential.created_by.full_name
      } : nil,
      updatedBy: credential.updated_by ? {
        id: credential.updated_by.id,
        name: credential.updated_by.full_name
      } : nil,
      createdAt: credential.created_at,
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

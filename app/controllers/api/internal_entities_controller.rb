class Api::InternalEntitiesController < ApplicationController
  before_action :set_internal_entity, only: [:show, :update, :destroy, :reveal_ein]
  before_action :authorize_management!, only: [:create, :update, :destroy]
  before_action :authorize_reveal!, only: [:reveal_ein]

  def index
    entities = InternalEntity.includes(:bank_accounts, :entity_signers).order(:name_legal)

    # Search
    if params[:q].present?
      entities = entities.search(params[:q])
    end

    # Filter by status
    if params[:status].present?
      entities = entities.where(status: params[:status])
    end

    # Filter by entity type
    if params[:entity_type].present?
      entities = entities.where(entity_type: params[:entity_type])
    end

    render json: entities.map { |entity| entity_summary_json(entity) }
  end

  def show
    render json: entity_detail_json(@internal_entity)
  end

  def create
    @internal_entity = InternalEntity.new(internal_entity_params)
    @internal_entity.created_by = current_user
    @internal_entity.updated_by = current_user

    # Handle EIN if provided
    if params[:ein].present?
      @internal_entity.set_ein(params[:ein])
    end

    if @internal_entity.save
      render json: entity_detail_json(@internal_entity), status: :created
    else
      render json: { errors: @internal_entity.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @internal_entity.updated_by = current_user

    # Handle EIN update separately
    if params[:ein].present?
      @internal_entity.set_ein(params[:ein])
      SecurityAuditLog.log_update(
        user: current_user,
        auditable: @internal_entity,
        field_name: 'ein',
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
    end

    if @internal_entity.update(internal_entity_params)
      render json: entity_detail_json(@internal_entity)
    else
      render json: { errors: @internal_entity.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @internal_entity.update!(status: 'dissolved')
    render json: { success: true }
  end

  # POST /api/internal_entities/:id/reveal_ein
  def reveal_ein
    # Log the reveal action
    SecurityAuditLog.log_reveal(
      user: current_user,
      auditable: @internal_entity,
      field_name: 'ein',
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    decrypted = @internal_entity.ein_decrypted
    if decrypted.present?
      render json: { ein: decrypted }
    else
      render json: { ein: nil, message: 'No EIN on file' }
    end
  end

  private

  def set_internal_entity
    @internal_entity = InternalEntity.find(params[:id])
  end

  def authorize_management!
    unless current_user&.can_manage_internal_entities?
      SecurityAuditLog.log_access_denied(
        user: current_user,
        auditable: @internal_entity || InternalEntity.new,
        action_attempted: action_name,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      ) if current_user
      render json: { error: 'Forbidden' }, status: :forbidden
    end
  end

  def authorize_reveal!
    unless current_user&.can_reveal_secrets?
      SecurityAuditLog.log_access_denied(
        user: current_user,
        auditable: @internal_entity,
        action_attempted: 'reveal_ein',
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      ) if current_user
      render json: { error: 'Forbidden' }, status: :forbidden
    end
  end

  def internal_entity_params
    params.permit(
      :name_legal,
      :name_short,
      :entity_type,
      :jurisdiction_country,
      :jurisdiction_state,
      :formation_date,
      :status,
      :tax_classification,
      :s_corp_effective_date,
      :registered_agent_name,
      :registered_agent_address,
      :primary_address,
      :mailing_address,
      :notes,
      metadata: {}
    )
  end

  def entity_summary_json(entity)
    {
      id: entity.id,
      nameLegal: entity.name_legal,
      nameShort: entity.name_short,
      displayName: entity.display_name,
      entityType: entity.entity_type,
      entityTypeLabel: entity.entity_type_label,
      jurisdictionCountry: entity.jurisdiction_country,
      jurisdictionState: entity.jurisdiction_state,
      status: entity.status,
      statusLabel: entity.status_label,
      einMasked: entity.ein_masked,
      einLast4: entity.ein_last4,
      bankAccountsCount: entity.bank_accounts.active.count,
      signersCount: entity.entity_signers.active.count,
      createdAt: entity.created_at,
      updatedAt: entity.updated_at
    }
  end

  def entity_detail_json(entity)
    {
      id: entity.id,
      nameLegal: entity.name_legal,
      nameShort: entity.name_short,
      displayName: entity.display_name,
      entityType: entity.entity_type,
      entityTypeLabel: entity.entity_type_label,
      jurisdictionCountry: entity.jurisdiction_country,
      jurisdictionState: entity.jurisdiction_state,
      fullJurisdiction: entity.full_jurisdiction,
      formationDate: entity.formation_date,
      status: entity.status,
      statusLabel: entity.status_label,
      # EIN is always masked - use reveal_ein endpoint for plaintext
      einMasked: entity.ein_masked,
      einLast4: entity.ein_last4,
      einPresent: entity.ein_present?,
      taxClassification: entity.tax_classification,
      taxClassificationLabel: entity.tax_classification_label,
      sCorpEffectiveDate: entity.s_corp_effective_date,
      registeredAgentName: entity.registered_agent_name,
      registeredAgentAddress: entity.registered_agent_address,
      primaryAddress: entity.primary_address,
      mailingAddress: entity.mailing_address,
      notes: entity.notes,
      metadata: entity.metadata,
      bankAccounts: entity.bank_accounts.order(is_primary: :desc, created_at: :desc).map { |ba|
        {
          id: ba.id,
          bankName: ba.bank_name,
          accountName: ba.account_name,
          accountType: ba.account_type,
          accountTypeLabel: ba.account_type_label,
          routingMasked: ba.routing_number_masked,
          accountMasked: ba.account_number_masked,
          routingLast4: ba.routing_last4,
          accountLast4: ba.account_last4,
          nickname: ba.nickname,
          isPrimary: ba.is_primary,
          status: ba.status,
          statusLabel: ba.status_label
        }
      },
      signers: entity.entity_signers.active.includes(:person).map { |es|
        {
          id: es.id,
          personId: es.person_id,
          firstName: es.person.first_name,
          lastName: es.person.last_name,
          fullName: es.person.full_name,
          role: es.role,
          roleLabel: es.role_label,
          effectiveFrom: es.effective_from,
          effectiveTo: es.effective_to,
          statusLabel: es.status_label
        }
      },
      documents: entity.document_links.includes(:document).map { |link|
        {
          id: link.document.id,
          linkId: link.id,
          name: link.document.name,
          title: link.document.display_title,
          category: link.document.category,
          relationship: link.relationship,
          visibility: link.visibility,
          createdAt: link.document.created_at
        }
      },
      createdBy: entity.created_by ? {
        id: entity.created_by.id,
        name: entity.created_by.full_name
      } : nil,
      updatedBy: entity.updated_by ? {
        id: entity.updated_by.id,
        name: entity.updated_by.full_name
      } : nil,
      createdAt: entity.created_at,
      updatedAt: entity.updated_at
    }
  end

  # Mock current_user if not implemented
  def current_user
    @current_user ||= begin
      user_id = request.headers['X-User-Id'] || params[:user_id]
      User.find_by(id: user_id) if user_id.present?
    end
  end
end

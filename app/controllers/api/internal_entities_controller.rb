class Api::InternalEntitiesController < ApplicationController
  before_action :set_internal_entity, only: [:show, :update, :destroy, :reveal_ein]
  before_action :authorize_management!, only: [:create, :update, :destroy]
  before_action :authorize_reveal!, only: [:reveal_ein]

  def index
    base_scope = InternalEntity.includes(:bank_accounts, :entity_signers, :document_links)

    # Search
    if params[:q].present?
      base_scope = base_scope.search(params[:q])
    end

    # Filter by status (supports array)
    if params[:status].present?
      statuses = Array(params[:status])
      base_scope = base_scope.where(status: statuses)
    end

    # Filter by entity type (supports array)
    if params[:entity_type].present?
      types = Array(params[:entity_type])
      base_scope = base_scope.where(entity_type: types)
    end

    # Filter by jurisdiction state (supports array)
    if params[:jurisdiction_state].present?
      states = Array(params[:jurisdiction_state])
      base_scope = base_scope.where(jurisdiction_state: states)
    end

    # Filter by has bank accounts
    if params[:has_bank_accounts].present?
      if params[:has_bank_accounts] == 'true'
        base_scope = base_scope.joins(:bank_accounts).where(bank_accounts: { status: 'active' }).distinct
      elsif params[:has_bank_accounts] == 'false'
        base_scope = base_scope.left_joins(:bank_accounts)
                               .where(bank_accounts: { id: nil })
                               .or(base_scope.left_joins(:bank_accounts).where.not(bank_accounts: { status: 'active' }))
                               .distinct
      end
    end

    # Filter by has signers
    if params[:has_signers].present?
      if params[:has_signers] == 'true'
        base_scope = base_scope.joins(:entity_signers).merge(EntitySigner.active).distinct
      elsif params[:has_signers] == 'false'
        active_signer_entity_ids = EntitySigner.active.select(:internal_entity_id)
        base_scope = base_scope.where.not(id: active_signer_entity_ids)
      end
    end

    # Filter by has documents
    if params[:has_documents].present?
      if params[:has_documents] == 'true'
        base_scope = base_scope.joins(:document_links).distinct
      elsif params[:has_documents] == 'false'
        base_scope = base_scope.left_joins(:document_links).where(document_links: { id: nil })
      end
    end

    # Build facets from unfiltered (but searched) scope for accurate counts
    facet_scope = InternalEntity.all
    facet_scope = facet_scope.search(params[:q]) if params[:q].present?

    facets = {
      entityType: InternalEntity::ENTITY_TYPES.map { |t| { value: t, count: facet_scope.where(entity_type: t).count } },
      status: InternalEntity::STATUSES.map { |s| { value: s, count: facet_scope.where(status: s).count } },
      jurisdictionState: facet_scope.where.not(jurisdiction_state: [nil, ''])
                                    .group(:jurisdiction_state)
                                    .order(:jurisdiction_state)
                                    .count
                                    .map { |state, count| { value: state, count: count } }
    }

    # Sorting
    sort_field = params[:sort] || 'name'
    entities = case sort_field
               when 'name' then base_scope.order(:name_legal)
               when 'updated_at', 'updatedAt' then base_scope.order(updated_at: :desc)
               when 'formation_date', 'formationDate' then base_scope.order(formation_date: :desc)
               else base_scope.order(:name_legal)
               end

    # Pagination
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 50).to_i.clamp(1, 100)
    total = entities.count
    entities = entities.limit(per_page).offset((page - 1) * per_page)

    render json: {
      internalEntities: entities.map { |entity| entity_summary_json(entity) },
      facets: facets,
      pageInfo: {
        page: page,
        perPage: per_page,
        total: total
      }
    }
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
    @internal_entity.destroy!
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
      formationDate: entity.formation_date,
      status: entity.status,
      statusLabel: entity.status_label,
      einMasked: entity.ein_masked,
      einLast4: entity.ein_last4,
      stats: {
        bankAccountsCount: entity.bank_accounts.active.count,
        signersCount: entity.entity_signers.active.count,
        documentsCount: entity.document_links.count
      },
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
      documents: entity.document_links.includes(:document).order('documents.created_at DESC').limit(10).map { |link|
        {
          id: link.document.id,
          linkId: link.id,
          name: link.document.name,
          title: link.document.display_title,
          category: link.document.category,
          docType: link.document.doc_type,
          status: link.document.status,
          relationship: link.relationship,
          visibility: link.visibility,
          createdAt: link.document.created_at,
          updatedAt: link.document.updated_at
        }
      },
      documentsCount: entity.document_links.count,
      linkedDeals: linked_deals_for_entity(entity),
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

  def linked_deals_for_entity(entity)
    # Find deals that share documents with this entity
    # First get all document IDs linked to this entity
    doc_ids = entity.document_links.pluck(:document_id)
    return [] if doc_ids.empty?

    # Find deals that also have links to these documents
    deal_ids = DocumentLink.where(document_id: doc_ids, linkable_type: 'Deal').pluck(:linkable_id).uniq
    return [] if deal_ids.empty?

    Deal.where(id: deal_ids).limit(10).map do |deal|
      {
        id: deal.id,
        name: deal.name,
        status: deal.status,
        company: deal.company&.name
      }
    end
  end

  # Mock current_user if not implemented
  def current_user
    @current_user ||= begin
      user_id = request.headers['X-User-Id'] || params[:user_id]
      User.find_by(id: user_id) if user_id.present?
    end
  end
end

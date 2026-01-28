class Api::BankAccountsController < ApplicationController
  before_action :set_bank_account, only: [:show, :update, :destroy, :reveal_numbers]
  before_action :set_internal_entity, only: [:create]
  before_action :authorize_management!, only: [:create, :update, :destroy]
  before_action :authorize_reveal!, only: [:reveal_numbers]

  def show
    render json: bank_account_json(@bank_account)
  end

  def create
    @bank_account = @internal_entity.bank_accounts.new(bank_account_params)
    @bank_account.created_by = current_user
    @bank_account.updated_by = current_user

    # Handle encrypted fields
    set_encrypted_fields(@bank_account)

    if @bank_account.save
      render json: bank_account_json(@bank_account), status: :created
    else
      render json: { errors: @bank_account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @bank_account.updated_by = current_user

    # Handle encrypted fields
    set_encrypted_fields(@bank_account)

    if @bank_account.update(bank_account_params)
      render json: bank_account_json(@bank_account)
    else
      render json: { errors: @bank_account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @bank_account.update!(status: 'closed')
    render json: { success: true }
  end

  # POST /api/bank_accounts/:id/reveal_numbers
  def reveal_numbers
    # Log the reveal action
    SecurityAuditLog.log_reveal(
      user: current_user,
      auditable: @bank_account,
      field_name: 'banking_numbers',
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    render json: {
      routingNumber: @bank_account.routing_number_decrypted,
      accountNumber: @bank_account.account_number_decrypted,
      swift: @bank_account.swift_decrypted
    }
  end

  private

  def set_bank_account
    @bank_account = BankAccount.find(params[:id])
  end

  def set_internal_entity
    @internal_entity = InternalEntity.find(params[:internal_entity_id])
  end

  def authorize_management!
    unless current_user&.can_manage_bank_accounts?
      log_access_denied('manage_bank_account')
      render json: { error: 'Forbidden' }, status: :forbidden
    end
  end

  def authorize_reveal!
    unless current_user&.can_reveal_secrets?
      log_access_denied('reveal_numbers')
      render json: { error: 'Forbidden' }, status: :forbidden
    end
  end

  def log_access_denied(action)
    return unless current_user
    SecurityAuditLog.log_access_denied(
      user: current_user,
      auditable: @bank_account || BankAccount.new,
      action_attempted: action,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  end

  def bank_account_params
    params.permit(
      :bank_name,
      :account_name,
      :account_type,
      :nickname,
      :is_primary,
      :status,
      metadata: {}
    )
  end

  def set_encrypted_fields(bank_account)
    if params[:routing_number].present?
      bank_account.set_routing_number(params[:routing_number])
      log_secret_update('routing_number') if bank_account.persisted?
    end

    if params[:account_number].present?
      bank_account.set_account_number(params[:account_number])
      log_secret_update('account_number') if bank_account.persisted?
    end

    if params[:swift].present?
      bank_account.set_swift(params[:swift])
      log_secret_update('swift') if bank_account.persisted?
    end
  end

  def log_secret_update(field_name)
    SecurityAuditLog.log_update(
      user: current_user,
      auditable: @bank_account,
      field_name: field_name,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  end

  def bank_account_json(bank_account)
    {
      id: bank_account.id,
      internalEntityId: bank_account.internal_entity_id,
      bankName: bank_account.bank_name,
      accountName: bank_account.account_name,
      accountType: bank_account.account_type,
      accountTypeLabel: bank_account.account_type_label,
      # Always masked - use reveal_numbers for plaintext
      routingMasked: bank_account.routing_number_masked,
      accountMasked: bank_account.account_number_masked,
      swiftMasked: bank_account.swift_masked,
      routingLast4: bank_account.routing_last4,
      accountLast4: bank_account.account_last4,
      nickname: bank_account.nickname,
      isPrimary: bank_account.is_primary,
      status: bank_account.status,
      statusLabel: bank_account.status_label,
      summary: bank_account.summary,
      createdAt: bank_account.created_at,
      updatedAt: bank_account.updated_at
    }
  end

  def current_user
    @current_user ||= begin
      user_id = request.headers['X-User-Id'] || params[:user_id]
      User.find_by(id: user_id) if user_id.present?
    end
  end
end

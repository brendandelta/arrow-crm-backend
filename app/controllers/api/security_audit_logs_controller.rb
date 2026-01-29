class Api::SecurityAuditLogsController < ApplicationController
  before_action :require_current_user
  before_action :authorize_audit_access!

  # GET /api/security_audit_logs
  def index
    logs = SecurityAuditLog.includes(:actor_user).order(created_at: :desc)

    # Filter by auditable
    if params[:auditable_type].present? && params[:auditable_id].present?
      logs = logs.where(auditable_type: params[:auditable_type], auditable_id: params[:auditable_id])
    end

    # Filter by action
    if params[:action_type].present?
      logs = logs.where(action: params[:action_type])
    end

    # Filter by actor
    if params[:actor_user_id].present?
      logs = logs.where(actor_user_id: params[:actor_user_id])
    end

    # Filter by date range
    if params[:after].present?
      logs = logs.where('created_at >= ?', Time.parse(params[:after]))
    end
    if params[:before].present?
      logs = logs.where('created_at <= ?', Time.parse(params[:before]))
    end

    # Pagination
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 50).to_i.clamp(1, 100)
    total = logs.count
    logs = logs.limit(per_page).offset((page - 1) * per_page)

    render json: {
      logs: logs.map { |log| audit_log_json(log) },
      pageInfo: {
        page: page,
        perPage: per_page,
        total: total
      }
    }
  end

  private

  def authorize_audit_access!
    # Only ops/admin can view audit logs
    unless current_user&.ops? || current_user&.admin?
      render json: { error: 'Access denied' }, status: :forbidden
    end
  end

  def audit_log_json(log)
    {
      id: log.id,
      action: log.action,
      actionLabel: action_label(log.action),
      auditableType: log.auditable_type,
      auditableId: log.auditable_id,
      actor: log.actor_user ? {
        id: log.actor_user.id,
        name: log.actor_user.full_name
      } : nil,
      metadata: log.metadata,
      ipAddress: log.metadata&.dig('ip_address'),
      createdAt: log.created_at
    }
  end

  def action_label(action)
    case action
    when 'reveal_secret' then 'Revealed Secret'
    when 'copy_secret' then 'Copied Secret'
    when 'update_secret' then 'Updated Secret'
    when 'access_denied' then 'Access Denied'
    when 'view_decrypted_field' then 'Viewed Decrypted Field'
    else action&.titleize || 'Unknown'
    end
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

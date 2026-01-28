class Api::DocumentLinksController < ApplicationController
  before_action :set_document_link, only: [:show, :update, :destroy]

  def index
    links = DocumentLink.includes(:document, :linkable).order(created_at: :desc)

    # Filter by document
    if params[:document_id].present?
      links = links.where(document_id: params[:document_id])
    end

    # Filter by linkable
    if params[:linkable_type].present? && params[:linkable_id].present?
      links = links.where(linkable_type: params[:linkable_type], linkable_id: params[:linkable_id])
    end

    # Filter by relationship
    if params[:relationship].present?
      links = links.by_relationship(params[:relationship])
    end

    # Filter by visibility
    if params[:visibility].present?
      links = links.where(visibility: params[:visibility])
    end

    render json: links.map { |link| document_link_json(link) }
  end

  def show
    render json: document_link_json(@document_link)
  end

  def create
    @document_link = DocumentLink.new(document_link_params)
    @document_link.created_by = current_user

    if @document_link.save
      render json: document_link_json(@document_link), status: :created
    else
      render json: { errors: @document_link.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @document_link.update(document_link_params.except(:document_id, :linkable_type, :linkable_id))
      render json: document_link_json(@document_link)
    else
      render json: { errors: @document_link.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @document_link.destroy
    render json: { success: true }
  end

  # Bulk create links
  # POST /api/document_links/bulk
  def bulk_create
    links = []
    errors = []

    params[:links].each_with_index do |link_params, index|
      link = DocumentLink.new(
        document_id: link_params[:document_id],
        linkable_type: link_params[:linkable_type],
        linkable_id: link_params[:linkable_id],
        relationship: link_params[:relationship] || 'general',
        visibility: link_params[:visibility] || 'default',
        created_by: current_user
      )

      if link.save
        links << document_link_json(link)
      else
        errors << { index: index, errors: link.errors.full_messages }
      end
    end

    if errors.empty?
      render json: { links: links }, status: :created
    else
      render json: { links: links, errors: errors }, status: :multi_status
    end
  end

  private

  def set_document_link
    @document_link = DocumentLink.find(params[:id])
  end

  def document_link_params
    params.permit(
      :document_id,
      :linkable_type,
      :linkable_id,
      :relationship,
      :visibility
    )
  end

  def document_link_json(link)
    {
      id: link.id,
      documentId: link.document_id,
      document: {
        id: link.document.id,
        name: link.document.name,
        title: link.document.display_title,
        category: link.document.category,
        status: link.document.status,
        sensitivity: link.document.sensitivity
      },
      linkableType: link.linkable_type,
      linkableId: link.linkable_id,
      linkableLabel: link.linkable_label,
      relationship: link.relationship,
      relationshipLabel: link.relationship_label,
      visibility: link.visibility,
      visibilityLabel: link.visibility_label,
      createdBy: link.created_by ? {
        id: link.created_by.id,
        name: link.created_by.full_name
      } : nil,
      createdAt: link.created_at,
      updatedAt: link.updated_at
    }
  end

  def current_user
    @current_user ||= begin
      user_id = request.headers['X-User-Id'] || params[:user_id]
      User.find_by(id: user_id) if user_id.present?
    end
  end
end

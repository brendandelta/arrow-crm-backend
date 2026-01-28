class Api::DocumentsController < ApplicationController
  before_action :set_document, only: [:show, :update, :destroy, :new_version]

  def index
    base_scope = Document.includes(:document_links, :uploaded_by)
    documents = base_scope

    # Search
    if params[:q].present?
      documents = documents.search(params[:q])
    end

    # Filter by category (supports array)
    if params[:category].present?
      categories = Array(params[:category])
      documents = documents.where(category: categories)
    end

    # Filter by status (supports array)
    if params[:status].present?
      statuses = Array(params[:status])
      documents = documents.where(status: statuses)
    end

    # Filter by sensitivity (supports array)
    if params[:sensitivity].present?
      sensitivities = Array(params[:sensitivity])
      documents = documents.where(sensitivity: sensitivities)
    end

    # Filter by doc_type (supports array)
    if params[:doc_type].present?
      doc_types = Array(params[:doc_type])
      documents = documents.where(doc_type: doc_types)
    end

    # Filter by linked entity type only (show all docs linked to that type)
    if params[:linkable_type].present? && params[:linkable_id].blank?
      documents = documents.joins(:document_links)
                           .where(document_links: { linkable_type: params[:linkable_type] })
                           .distinct
    end

    # Filter by specific linked entity
    if params[:linkable_type].present? && params[:linkable_id].present?
      documents = documents.joins(:document_links)
                           .where(document_links: {
                             linkable_type: params[:linkable_type],
                             linkable_id: params[:linkable_id]
                           })
                           .distinct
    end

    # Filter by confidential only
    if params[:confidential] == 'true'
      documents = documents.confidential
    end

    # Filter by needs_review (draft status)
    if params[:needs_review] == 'true'
      documents = documents.where(status: 'draft')
    end

    # Date range filtering
    if params[:updated_after].present?
      documents = documents.where('documents.updated_at >= ?', Time.parse(params[:updated_after]))
    end
    if params[:updated_before].present?
      documents = documents.where('documents.updated_at <= ?', Time.parse(params[:updated_before]))
    end

    # Sorting
    case params[:sort]
    when 'title'
      documents = documents.order('COALESCE(title, name) ASC')
    when 'updatedAt'
      documents = documents.order(updated_at: :desc)
    when 'createdAt'
      documents = documents.order(created_at: :desc)
    else
      documents = documents.order(updated_at: :desc)
    end

    # Get total before pagination
    total = documents.count

    # Pagination
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 50).to_i.clamp(1, 100)
    documents = documents.limit(per_page).offset((page - 1) * per_page)

    # Build facets with counts (from full filtered set, not paginated)
    facets = build_facets(base_scope, params)

    render json: {
      documents: documents.map { |doc| document_summary_json(doc) },
      pageInfo: {
        page: page,
        perPage: per_page,
        total: total
      },
      facets: facets
    }
  end

  def show
    render json: document_detail_json(@document, include_preview_url: true)
  end

  def create
    @document = Document.new(document_params)
    @document.uploaded_by = current_user
    @document.title ||= @document.name

    # Handle file upload if present
    if params[:file].present?
      @document.file.attach(params[:file])
      @document.file_size_bytes = params[:file].size
      @document.file_type = params[:file].content_type
    end

    if @document.save
      # Create document links if provided
      create_document_links(@document)
      render json: document_detail_json(@document), status: :created
    else
      render json: { errors: @document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @document.update(document_params)
      render json: document_detail_json(@document)
    else
      render json: { errors: @document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @document.destroy
    render json: { success: true }
  end

  # POST /api/documents/:id/new_version
  def new_version
    new_doc = @document.create_new_version(document_params)
    new_doc.uploaded_by = current_user

    # Handle file upload
    if params[:file].present?
      new_doc.file.attach(params[:file])
      new_doc.file_size_bytes = params[:file].size
      new_doc.file_type = params[:file].content_type
    end

    if new_doc.save
      # Copy document links to new version
      @document.document_links.find_each do |link|
        new_doc.document_links.create!(
          linkable: link.linkable,
          relationship: link.relationship,
          visibility: link.visibility,
          created_by: current_user
        )
      end

      # Mark old version as superseded
      @document.update!(status: 'superseded')

      render json: document_detail_json(new_doc), status: :created
    else
      render json: { errors: new_doc.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end

  def document_params
    params.permit(
      :name,
      :title,
      :description,
      :category,
      :doc_type,
      :status,
      :source,
      :sensitivity,
      :url,
      :expires_at,
      :is_confidential,
      :parent_type,
      :parent_id
    )
  end

  def create_document_links(document)
    return unless params[:links].is_a?(Array)

    params[:links].each do |link_params|
      next unless link_params[:linkable_type].present? && link_params[:linkable_id].present?

      document.document_links.create!(
        linkable_type: link_params[:linkable_type],
        linkable_id: link_params[:linkable_id],
        relationship: link_params[:relationship] || 'general',
        visibility: link_params[:visibility] || 'default',
        created_by: current_user
      )
    end
  end

  def build_facets(base_scope, filter_params)
    # Build facets from the base scope (before filtering)
    # Each facet shows count of documents in that category
    {
      category: Document::CATEGORIES.map do |cat|
        { value: cat, label: cat.titleize, count: base_scope.where(category: cat).count }
      end.select { |f| f[:count] > 0 },
      docType: Document::DILIGENCE_KINDS.map do |dt|
        { value: dt, label: dt.titleize.gsub('_', ' '), count: base_scope.where(doc_type: dt).count }
      end.select { |f| f[:count] > 0 },
      status: Document::STATUSES.map do |s|
        { value: s, label: s.titleize, count: base_scope.where(status: s).count }
      end.select { |f| f[:count] > 0 },
      sensitivity: Document::SENSITIVITIES.map do |s|
        label = case s
                when 'highly_confidential' then 'Highly Confidential'
                else s.titleize
                end
        { value: s, label: label, count: base_scope.where(sensitivity: s).count }
      end.select { |f| f[:count] > 0 },
      linkableType: [
        { value: 'Deal', label: 'Deals', count: base_scope.joins(:document_links).where(document_links: { linkable_type: 'Deal' }).distinct.count },
        { value: 'Organization', label: 'Organizations', count: base_scope.joins(:document_links).where(document_links: { linkable_type: 'Organization' }).distinct.count },
        { value: 'Person', label: 'People', count: base_scope.joins(:document_links).where(document_links: { linkable_type: 'Person' }).distinct.count },
        { value: 'InternalEntity', label: 'Internal Entities', count: base_scope.joins(:document_links).where(document_links: { linkable_type: 'InternalEntity' }).distinct.count }
      ].select { |f| f[:count] > 0 }
    }
  end

  def document_summary_json(doc)
    {
      id: doc.id,
      name: doc.name,
      title: doc.display_title,
      description: doc.description,
      category: doc.category,
      categoryLabel: doc.category_label,
      docType: doc.doc_type,
      status: doc.status,
      statusLabel: doc.status_label,
      source: doc.source,
      sourceLabel: doc.source_label,
      sensitivity: doc.sensitivity,
      sensitivityLabel: doc.sensitivity_label,
      isImage: doc.image?,
      isPdf: doc.pdf?,
      version: doc.version,
      file: {
        filename: doc.name,
        contentType: doc.file_type,
        byteSize: doc.file_size_bytes
      },
      links: doc.document_links.includes(:linkable).map { |link|
        {
          id: link.id,
          linkableType: link.linkable_type,
          linkableId: link.linkable_id,
          relationship: link.relationship,
          label: link.linkable_label
        }
      },
      uploadedBy: doc.uploaded_by ? {
        id: doc.uploaded_by.id,
        name: doc.uploaded_by.full_name
      } : nil,
      createdAt: doc.created_at,
      updatedAt: doc.updated_at
    }
  end

  def document_detail_json(doc, include_preview_url: false)
    json = {
      id: doc.id,
      name: doc.name,
      title: doc.display_title,
      description: doc.description,
      category: doc.category,
      categoryLabel: doc.category_label,
      docType: doc.doc_type,
      status: doc.status,
      statusLabel: doc.status_label,
      source: doc.source,
      sourceLabel: doc.source_label,
      sensitivity: doc.sensitivity,
      sensitivityLabel: doc.sensitivity_label,
      fileType: doc.file_type,
      fileSizeBytes: doc.file_size_bytes,
      fileSizeMb: doc.file_size_mb,
      fileExtension: doc.file_extension,
      isImage: doc.image?,
      isPdf: doc.pdf?,
      isSpreadsheet: doc.spreadsheet?,
      isDocument: doc.document?,
      url: doc.url,
      fileUrl: doc.file.attached? ? Rails.application.routes.url_helpers.rails_blob_url(doc.file, only_path: true) : nil,
      version: doc.version,
      versionGroupId: doc.version_group_id,
      isLatestVersion: doc.latest_version?,
      checksum: doc.checksum,
      expiresAt: doc.expires_at,
      isExpired: doc.expired?,
      isExpiringSoon: doc.expiring_soon?,
      isConfidential: doc.is_confidential,
      links: doc.document_links.includes(:linkable).map { |link|
        {
          id: link.id,
          linkableType: link.linkable_type,
          linkableId: link.linkable_id,
          linkableLabel: link.linkable_label,
          relationship: link.relationship,
          relationshipLabel: link.relationship_label,
          visibility: link.visibility,
          visibilityLabel: link.visibility_label
        }
      },
      versions: doc.version_history.map { |v|
        {
          id: v.id,
          version: v.version,
          status: v.status,
          filename: v.name,
          createdAt: v.created_at
        }
      },
      # Legacy parent (for backwards compatibility)
      parentType: doc.parent_type,
      parentId: doc.parent_id,
      uploadedBy: doc.uploaded_by ? {
        id: doc.uploaded_by.id,
        name: doc.uploaded_by.full_name
      } : nil,
      createdAt: doc.created_at,
      updatedAt: doc.updated_at
    }

    # Add preview URL for PDFs and images (short-lived presigned URL)
    if include_preview_url && doc.file.attached? && (doc.pdf? || doc.image?)
      json[:previewUrl] = Rails.application.routes.url_helpers.rails_blob_url(
        doc.file,
        disposition: 'inline',
        expires_in: 1.hour,
        only_path: true
      )
    end

    json
  end

  def current_user
    @current_user ||= begin
      user_id = request.headers['X-User-Id'] || params[:user_id]
      User.find_by(id: user_id) if user_id.present?
    end
  end
end

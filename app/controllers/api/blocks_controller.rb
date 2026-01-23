class Api::BlocksController < ApplicationController
  before_action :set_block, only: [:show, :update, :destroy]

  def index
    blocks = Block.includes(:deal, :seller, :contact, :broker, :broker_contact, :tasks, block_contacts: :person, deal: :company)
                  .order(created_at: :desc)

    render json: blocks.map { |block| block_json(block) }
  end

  def show
    render json: block_json(@block, full: true)
  end

  def create
    block = Block.new(block_params)

    if block.save
      sync_block_contacts(block) if params[:block_contacts].present?
      render json: { id: block.id, success: true }, status: :created
    else
      render json: { errors: block.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @block.update(block_params)
      sync_block_contacts(@block) if params.key?(:block_contacts)
      @block.reload
      render json: block_json(@block, full: true)
    else
      render json: { errors: @block.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @block.destroy
    render json: { success: true }
  end

  private

  def set_block
    @block = Block.includes(:deal, :seller, :contact, :broker, :broker_contact, :tasks, block_contacts: :person, deal: :company).find(params[:id])
  end

  def block_params
    params.permit(
      :deal_id, :seller_id, :contact_id, :seller_type,
      :share_class, :shares, :price_cents, :total_cents, :min_size_cents,
      :implied_valuation_cents, :discount_pct, :valuation_date,
      :status, :expires_at, :source, :source_detail,
      :broker_id, :broker_contact_id, :broker_fee_bps,
      :exclusivity, :exclusivity_until,
      :verified, :verified_at, :verification_notes, :internal_notes,
      :heat, :terms,
      :rofr, :transfer_approval_required, :issuer_approval_required
    )
  end

  def taskable_task_json(task)
    {
      id: task.id,
      subject: task.subject,
      dueAt: task.due_at,
      completed: task.completed,
      priority: task.priority,
      priorityLabel: task.priority_label,
      status: task.status,
      overdue: task.overdue?,
      assignedTo: task.assigned_to ? {
        id: task.assigned_to.id,
        firstName: task.assigned_to.first_name,
        lastName: task.assigned_to.last_name
      } : nil
    }
  end

  def next_task_json(tasks)
    next_task = tasks.select { |t| !t.completed? }.min_by { |t| t.due_at || Time.new(9999) }
    return nil unless next_task

    {
      id: next_task.id,
      subject: next_task.subject,
      dueAt: next_task.due_at,
      overdue: next_task.overdue?,
      assignedTo: next_task.assigned_to ? {
        id: next_task.assigned_to.id,
        firstName: next_task.assigned_to.first_name,
        lastName: next_task.assigned_to.last_name
      } : nil
    }
  end

  def sync_block_contacts(block)
    incoming = (params[:block_contacts] || []).map { |bc| bc.permit(:person_id, :role, :notes).to_h }

    # Replace all block_contacts with the incoming set
    block.block_contacts.destroy_all
    incoming.each do |attrs|
      block.block_contacts.create!(attrs)
    end
  end

  def block_json(block, full: false)
    data = {
      id: block.id,
      dealId: block.deal_id,
      dealName: block.deal&.name,
      underlyingCompany: block.underlying_company ? {
        id: block.underlying_company.id,
        name: block.underlying_company.name,
        kind: block.underlying_company.kind
      } : nil,
      seller: block.seller ? {
        id: block.seller.id,
        name: block.seller.name,
        kind: block.seller.kind
      } : nil,
      sellerType: block.seller_type,
      contact: block.contact ? {
        id: block.contact.id,
        firstName: block.contact.first_name,
        lastName: block.contact.last_name,
        title: block.contact.title,
        email: block.contact.primary_email,
        phone: block.contact.primary_phone
      } : nil,
      broker: block.broker ? {
        id: block.broker.id,
        name: block.broker.name
      } : nil,
      brokerContact: block.broker_contact ? {
        id: block.broker_contact.id,
        firstName: block.broker_contact.first_name,
        lastName: block.broker_contact.last_name,
        email: block.broker_contact.primary_email,
        phone: block.broker_contact.primary_phone
      } : nil,
      shareClass: block.share_class,
      shares: block.shares,
      priceCents: block.price_cents,
      totalCents: block.total_cents,
      minSizeCents: block.min_size_cents,
      impliedValuationCents: block.implied_valuation_cents,
      discountPct: block.discount_pct,
      valuationDate: block.valuation_date,
      status: block.status,
      heat: block.heat,
      heatLabel: block.heat_label,
      terms: block.terms,
      expiresAt: block.expires_at,
      source: block.source,
      sourceDetail: block.source_detail,
      brokerFeeBps: block.broker_fee_bps,
      exclusivity: block.exclusivity,
      exclusivityUntil: block.exclusivity_until,
      verified: block.verified,
      verifiedAt: block.verified_at,
      rofr: block.rofr,
      transferApprovalRequired: block.transfer_approval_required,
      issuerApprovalRequired: block.issuer_approval_required,
      constraints: block.constraints,
      tasks: block.tasks.select { |t| !t.completed? }.sort_by { |t| t.due_at || Time.new(9999) }.map { |t| taskable_task_json(t) },
      nextTask: next_task_json(block.tasks),
      createdAt: block.created_at,
      updatedAt: block.updated_at
    }

    if full
      data[:verificationNotes] = block.verification_notes
      data[:internalNotes] = block.internal_notes
      data[:sellerContacts] = block.block_contacts.select { |bc| bc.role == "seller_contact" }.map do |bc|
        {
          id: bc.id,
          personId: bc.person_id,
          firstName: bc.person.first_name,
          lastName: bc.person.last_name,
          email: bc.person.primary_email,
          phone: bc.person.primary_phone,
          notes: bc.notes
        }
      end
      data[:brokerContacts] = block.block_contacts.select { |bc| bc.role == "broker_contact" }.map do |bc|
        {
          id: bc.id,
          personId: bc.person_id,
          firstName: bc.person.first_name,
          lastName: bc.person.last_name,
          email: bc.person.primary_email,
          phone: bc.person.primary_phone,
          notes: bc.notes
        }
      end
      data[:interests] = block.interests.includes(:investor, :contact).map do |interest|
        {
          id: interest.id,
          investor: interest.investor ? {
            id: interest.investor.id,
            name: interest.investor.name
          } : nil,
          allocatedCents: interest.allocated_cents,
          status: interest.status
        }
      end
    end

    data
  end
end

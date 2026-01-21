class Api::DealsController < ApplicationController
  def index
    deals = Deal.includes(:company, :blocks, :interests, :deal_targets).order(created_at: :desc)

    render json: deals.map { |deal|
      {
        id: deal.id,
        name: deal.name,
        company: deal.company&.name,
        companyId: deal.company&.id,
        sector: deal.company&.sector,
        status: deal.status,
        stage: deal.stage,
        kind: deal.kind,
        dealOwner: deal.deal_owner,
        priority: deal.priority,
        priorityLabel: deal.priority_label,
        blocks: deal.blocks.count,
        interests: deal.interests.count,
        targets: deal.deal_targets.count,
        activeTargets: deal.deal_targets.active.count,
        committed: deal.committed_cents || 0,
        closed: deal.closed_cents || 0,
        softCircled: deal.soft_circled_cents,
        valuation: deal.valuation_cents,
        expectedClose: deal.expected_close,
        sourcedAt: deal.sourced_at
      }
    }
  end

  def show
    deal = Deal.includes(
      :company,
      blocks: [:seller, :contact, :broker, :broker_contact],
      interests: [:investor, :contact, :decision_maker],
      deal_targets: [:target, :owner]
    ).find(params[:id])

    render json: {
      id: deal.id,
      name: deal.name,
      company: {
        id: deal.company&.id,
        name: deal.company&.name,
        kind: deal.company&.kind,
        sector: deal.company&.sector,
        website: deal.company&.website,
        logoUrl: deal.company&.logo_url
      },
      status: deal.status,
      stage: deal.stage,
      kind: deal.kind,
      dealOwner: deal.deal_owner,
      priority: deal.priority,
      priorityLabel: deal.priority_label,
      confidence: deal.confidence,
      committed: deal.committed_cents || 0,
      closed: deal.closed_cents || 0,
      softCircled: deal.soft_circled_cents,
      totalCommitted: deal.total_committed_cents,
      target: deal.target_cents,
      valuation: deal.valuation_cents,
      sharePrice: deal.share_price_cents,
      shareClass: deal.share_class,
      expectedClose: deal.expected_close,
      deadline: deal.deadline,
      sourcedAt: deal.sourced_at,
      qualifiedAt: deal.qualified_at,
      closedAt: deal.closed_at,
      source: deal.source,
      sourceDetail: deal.source_detail,
      driveUrl: deal.drive_url,
      dataRoomUrl: deal.data_room_url,
      deckUrl: deal.deck_url,
      notionUrl: deal.notion_url,
      tags: deal.tags || [],
      notes: deal.internal_notes,
      structureNotes: deal.structure_notes,
      blocks: deal.blocks.map { |b| block_json(b) },
      interests: deal.interests.map { |i| interest_json(i) },
      targets: deal.deal_targets.map { |t| deal_target_json(t) },
      targetsSummary: {
        total: deal.deal_targets.count,
        active: deal.deal_targets.active.count,
        notStarted: deal.deal_targets.not_started.count,
        contacted: deal.deal_targets.contacted.count,
        engaged: deal.deal_targets.engaged.count,
        committed: deal.deal_targets.committed.count,
        passed: deal.deal_targets.passed.count
      },
      recentActivities: deal.activities.recent.limit(5).map { |a|
        {
          id: a.id,
          kind: a.kind,
          subject: a.subject,
          occurredAt: a.occurred_at,
          startsAt: a.starts_at,
          outcome: a.outcome
        }
      },
      createdAt: deal.created_at,
      updatedAt: deal.updated_at
    }
  end

  def create
    deal = Deal.new(deal_params)

    if deal.save
      render json: { id: deal.id, success: true }, status: :created
    else
      render json: { errors: deal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    deal = Deal.find(params[:id])

    if deal.update(deal_params)
      render json: { id: deal.id, success: true }
    else
      render json: { errors: deal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def deal_params
    params.permit(
      :name, :kind, :company_id, :status, :stage, :priority, :confidence,
      :deal_owner, :target_cents, :committed_cents, :closed_cents, :valuation_cents,
      :share_price_cents, :share_class, :expected_close, :deadline,
      :sourced_at, :qualified_at, :closed_at, :source, :source_detail,
      :drive_url, :data_room_url, :deck_url, :notion_url,
      :internal_notes, :structure_notes, :owner_id,
      tags: [], team_member_ids: []
    )
  end

  def block_json(block)
    {
      id: block.id,
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
        title: block.contact.current_employment&.title,
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
      status: block.status,
      heat: block.heat,
      heatLabel: block.heat_label,
      terms: block.terms,
      expiresAt: block.expires_at,
      source: block.source,
      sourceDetail: block.source_detail,
      verified: block.verified,
      internalNotes: block.internal_notes,
      createdAt: block.created_at
    }
  end

  def interest_json(interest)
    {
      id: interest.id,
      investor: interest.investor ? {
        id: interest.investor.id,
        name: interest.investor.name,
        kind: interest.investor.kind
      } : nil,
      contact: interest.contact ? {
        id: interest.contact.id,
        firstName: interest.contact.first_name,
        lastName: interest.contact.last_name,
        title: interest.contact.current_employment&.title,
        email: interest.contact.primary_email
      } : nil,
      decisionMaker: interest.decision_maker ? {
        id: interest.decision_maker.id,
        firstName: interest.decision_maker.first_name,
        lastName: interest.decision_maker.last_name
      } : nil,
      targetCents: interest.target_cents,
      minCents: interest.min_cents,
      maxCents: interest.max_cents,
      committedCents: interest.committed_cents,
      allocatedCents: interest.allocated_cents,
      allocatedBlockId: interest.allocated_block_id,
      status: interest.status,
      source: interest.source,
      nextStep: interest.next_step,
      nextStepAt: interest.next_step_at,
      internalNotes: interest.internal_notes,
      createdAt: interest.created_at
    }
  end

  def deal_target_json(deal_target)
    target = deal_target.target
    {
      id: deal_target.id,
      targetType: deal_target.target_type,
      targetId: deal_target.target_id,
      targetName: deal_target.target_name,
      target: case deal_target.target_type
              when "Organization"
                {
                  id: target&.id,
                  name: target&.name,
                  kind: target&.kind,
                  warmth: target&.warmth
                }
              when "Person"
                {
                  id: target&.id,
                  firstName: target&.first_name,
                  lastName: target&.last_name,
                  email: target&.primary_email,
                  organization: target&.current_org ? {
                    id: target.current_org.id,
                    name: target.current_org.name
                  } : nil,
                  warmth: target&.warmth
                }
              end,
      status: deal_target.status,
      role: deal_target.role,
      priority: deal_target.priority,
      priorityLabel: deal_target.priority_label,
      lastActivityAt: deal_target.last_activity_at,
      activityCount: deal_target.activity_count,
      nextStep: deal_target.next_step,
      nextStepAt: deal_target.next_step_at,
      owner: deal_target.owner ? {
        id: deal_target.owner.id,
        firstName: deal_target.owner.first_name,
        lastName: deal_target.owner.last_name
      } : nil
    }
  end
end

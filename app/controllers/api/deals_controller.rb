class Api::DealsController < ApplicationController
  def index
    deals = Deal.includes(:company, :blocks, :interests).order(created_at: :desc)

    render json: deals.map { |deal|
      {
        id: deal.id,
        name: deal.name,
        company: deal.company&.name,
        sector: deal.company&.sector,
        status: deal.status,
        stage: deal.stage,
        kind: deal.kind,
        priority: deal.priority,
        blocks: deal.blocks.count,
        interests: deal.interests.count,
        committed: deal.committed_cents || 0,
        closed: deal.closed_cents || 0,
        valuation: deal.valuation_cents,
        expectedClose: deal.expected_close,
        sourcedAt: deal.sourced_at
      }
    }
  end

  def show
    deal = Deal.includes(:company, :blocks, :interests, :meetings).find(params[:id])

    render json: {
      id: deal.id,
      name: deal.name,
      company: {
        id: deal.company&.id,
        name: deal.company&.name,
        sector: deal.company&.sector,
        website: deal.company&.website
      },
      status: deal.status,
      stage: deal.stage,
      kind: deal.kind,
      priority: deal.priority,
      confidence: deal.confidence,
      committed: deal.committed_cents || 0,
      closed: deal.closed_cents || 0,
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
      tags: deal.tags || [],
      notes: deal.internal_notes,
      structureNotes: deal.structure_notes,
      blocks: deal.blocks.map { |b|
        {
          id: b.id,
          status: b.status,
          shares: b.shares,
          pricePerShare: b.price_cents,
          total: b.total_cents,
          shareClass: b.share_class,
          source: b.source
        }
      },
      interests: deal.interests.includes(:investor).map { |i|
        {
          id: i.id,
          investor: i.investor&.name,
          status: i.status,
          target: i.target_cents,
          committed: i.committed_cents
        }
      },
      meetings: deal.meetings.order(starts_at: :desc).limit(5).map { |m|
        {
          id: m.id,
          title: m.title,
          startsAt: m.starts_at,
          kind: m.kind
        }
      },
      createdAt: deal.created_at,
      updatedAt: deal.updated_at
    }
  end
end

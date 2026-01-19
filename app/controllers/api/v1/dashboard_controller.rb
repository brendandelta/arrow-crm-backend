class Api::V1::DashboardController < ApplicationController
  def show
    # Deal stats
    deals = Deal.all
    live_deals = deals.where(status: "live")

    # Organization stats
    orgs = Organization.all

    # People stats
    people = Person.all

    # Meeting stats
    meetings = Meeting.all
    week_start = Date.current.beginning_of_week
    meetings_this_week = meetings.where("starts_at >= ?", week_start)

    # Pipeline
    total_committed = deals.sum(:committed_cents) || 0
    total_closed = deals.sum(:closed_cents) || 0

    render json: {
      stats: {
        deals: {
          total: deals.count,
          live: live_deals.count,
          sourcing: deals.where(status: "sourcing").count
        },
        organizations: {
          total: orgs.count,
          funds: orgs.where(kind: "fund").count,
          companies: orgs.where(kind: "company").count
        },
        people: {
          total: people.count,
          champions: people.where(warmth: 3).count,
          hot: people.where(warmth: 2).count
        },
        meetings: {
          total: meetings.count,
          thisWeek: meetings_this_week.count
        },
        pipeline: {
          committed: total_committed,
          closed: total_closed
        }
      },
      liveDeals: live_deals.includes(:company, :blocks, :interests).limit(5).map { |deal|
        {
          id: deal.id,
          name: deal.name,
          company: deal.company&.name,
          committed: deal.committed_cents || 0,
          blocks: deal.blocks.count,
          interests: deal.interests.count
        }
      },
      recentMeetings: meetings.includes(:deal).order(starts_at: :desc).limit(5).map { |meeting|
        {
          id: meeting.id,
          title: meeting.title,
          deal: meeting.deal&.name,
          attendees: (meeting.attendee_ids&.length || 0) + (meeting.internal_attendee_ids&.length || 0),
          startsAt: meeting.starts_at
        }
      }
    }
  end
end

class Api::DashboardController < ApplicationController
  def show
    # Deal stats
    deals = Deal.all
    live_deals = deals.where(status: "live")

    # Organization stats
    orgs = Organization.all

    # People stats
    people = Person.all

    # Activity stats
    activities = Activity.all
    week_start = Date.current.beginning_of_week
    activities_this_week = activities.where("occurred_at >= ?", week_start)
    scheduled_activities = activities.scheduled

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
        activities: {
          total: activities.count,
          thisWeek: activities_this_week.count,
          scheduled: scheduled_activities.count
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
      recentActivities: activities.includes(:deal, :activity_attendees).recent.limit(5).map { |activity|
        {
          id: activity.id,
          kind: activity.kind,
          subject: activity.subject,
          deal: activity.deal&.name,
          attendees: activity.activity_attendees.count,
          occurredAt: activity.occurred_at,
          startsAt: activity.starts_at
        }
      }
    }
  end
end

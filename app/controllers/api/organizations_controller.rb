class Api::OrganizationsController < ApplicationController
  def index
    organizations = Organization.includes(:employments, :deals).order(:name)

    render json: organizations.map { |org|
      {
        id: org.id,
        name: org.name,
        kind: org.kind,
        sector: org.sector,
        city: org.city,
        country: org.country,
        website: org.website,
        warmth: org.warmth || 0,
        peopleCount: org.employments.where(is_current: true).count,
        dealsCount: org.deals.count,
        lastContactedAt: org.last_contacted_at
      }
    }
  end

  def show
    org = Organization.includes(:employments, :people, :deals).find(params[:id])

    render json: {
      id: org.id,
      name: org.name,
      legalName: org.legal_name,
      kind: org.kind,
      description: org.description,
      logoUrl: org.logo_url,
      website: org.website,
      linkedinUrl: org.linkedin_url,
      twitterUrl: org.twitter_url,
      phone: org.phone,
      email: org.email,
      address: {
        line1: org.address_line1,
        line2: org.address_line2,
        city: org.city,
        state: org.state,
        postalCode: org.postal_code,
        country: org.country
      },
      sector: org.sector,
      subSector: org.sub_sector,
      stage: org.stage,
      employeeRange: org.employee_range,
      warmth: org.warmth || 0,
      tags: org.tags || [],
      notes: org.internal_notes,
      meta: org.meta || {},
      lastContactedAt: org.last_contacted_at,
      nextFollowUpAt: org.next_follow_up_at,
      people: org.employments.where(is_current: true).includes(:person).map { |emp|
        {
          id: emp.person.id,
          firstName: emp.person.first_name,
          lastName: emp.person.last_name,
          title: emp.title,
          email: emp.email || emp.person.primary_email,
          warmth: emp.person.warmth
        }
      },
      deals: org.deals.map { |d|
        {
          id: d.id,
          name: d.name,
          status: d.status,
          kind: d.kind,
          committed: d.committed_cents
        }
      },
      createdAt: org.created_at,
      updatedAt: org.updated_at
    }
  end
end

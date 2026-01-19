class Api::V1::PeopleController < ApplicationController
  def index
    people = Person.includes(employments: :organization).order(:last_name, :first_name)

    render json: people.map { |person|
      current = person.current_employment
      {
        id: person.id,
        firstName: person.first_name,
        lastName: person.last_name,
        title: current&.title,
        org: current&.organization&.name,
        orgKind: current&.organization&.kind,
        email: person.primary_email,
        warmth: person.warmth || 0,
        city: person.city,
        country: person.country,
        linkedin: person.linkedin_url,
        lastContactedAt: person.last_contacted_at,
        tags: person.tags || []
      }
    }
  end

  def show
    person = Person.includes(employments: :organization).find(params[:id])
    current = person.current_employment

    render json: {
      id: person.id,
      firstName: person.first_name,
      lastName: person.last_name,
      nickname: person.nickname,
      prefix: person.prefix,
      suffix: person.suffix,
      emails: person.emails || [],
      phones: person.phones || [],
      preferredContact: person.preferred_contact,
      address: {
        line1: person.address_line1,
        line2: person.address_line2,
        city: person.city,
        state: person.state,
        postalCode: person.postal_code,
        country: person.country
      },
      title: person.title,
      linkedinUrl: person.linkedin_url,
      twitterUrl: person.twitter_url,
      bio: person.bio,
      birthday: person.birthday,
      avatarUrl: person.avatar_url,
      warmth: person.warmth || 0,
      tags: person.tags || [],
      notes: person.internal_notes,
      source: person.source,
      sourceDetail: person.source_detail,
      lastContactedAt: person.last_contacted_at,
      nextFollowUpAt: person.next_follow_up_at,
      contactCount: person.contact_count,
      currentEmployment: current ? {
        title: current.title,
        organization: {
          id: current.organization.id,
          name: current.organization.name,
          kind: current.organization.kind
        }
      } : nil,
      employments: person.employments.includes(:organization).map { |emp|
        {
          id: emp.id,
          title: emp.title,
          department: emp.department,
          isCurrent: emp.is_current,
          isPrimary: emp.is_primary,
          startedAt: emp.started_at,
          endedAt: emp.ended_at,
          organization: {
            id: emp.organization.id,
            name: emp.organization.name,
            kind: emp.organization.kind
          }
        }
      },
      createdAt: person.created_at,
      updatedAt: person.updated_at
    }
  end
end

class Api::PeopleController < ApplicationController
  def index
    people = Person.includes(employments: :organization).order(:last_name, :first_name)

    if params[:q].present?
      q = "%#{params[:q]}%"
      people = people.where("first_name ILIKE ? OR last_name ILIKE ? OR (first_name || ' ' || last_name) ILIKE ?", q, q, q)
    end

    render json: people.map { |person|
      current = person.current_employment
      {
        id: person.id,
        firstName: person.first_name,
        lastName: person.last_name,
        title: current&.title,
        department: current&.department,
        org: current&.organization&.name,
        orgId: current&.organization&.id,
        orgKind: current&.organization&.kind,
        email: person.primary_email,
        phone: person.primary_phone,
        warmth: person.warmth || 0,
        city: person.city,
        state: person.state,
        country: person.country,
        linkedin: person.linkedin_url,
        twitter: person.twitter_url,
        instagram: person.instagram_url,
        source: person.source,
        lastContactedAt: person.last_contacted_at,
        nextFollowUpAt: person.next_follow_up_at,
        contactCount: person.contact_count || 0,
        tags: person.tags || [],
        createdAt: person.created_at
      }
    }
  end

  def show
    person = Person.includes(employments: :organization).find(params[:id])
    current = person.current_employment

    # Find related deals where this person is referred_by
    related_deals = Deal.includes(:company).where(referred_by_id: person.id)

    # Find interests where this person is contact, decision_maker, or introduced_by
    related_interests = Interest.includes(:deal, :investor)
      .where("contact_id = ? OR decision_maker_id = ? OR introduced_by_id = ?", person.id, person.id, person.id)

    # Find blocks where this person is contact or broker_contact
    related_blocks = Block.includes(:deal, :seller)
      .where("contact_id = ? OR broker_contact_id = ?", person.id, person.id)

    # Find activities regarding this person or where they're an attendee
    regarding_activities = Activity.where(regarding_type: "Person", regarding_id: person.id)
    attendee_activities = Activity.joins(:activity_attendees)
      .where(activity_attendees: { attendee_type: "Person", attendee_id: person.id })
    recent_activities = Activity.where(id: regarding_activities.select(:id))
      .or(Activity.where(id: attendee_activities.select(:id)))
      .distinct
      .order(occurred_at: :desc)
      .limit(10)

    # Find relationships involving this person
    person_relationships = Relationship.includes(:relationship_type)
      .where("(source_type = 'Person' AND source_id = ?) OR (target_type = 'Person' AND target_id = ?)", person.id, person.id)
      .where(status: "active")

    # Find edges involving this person
    person_edges = Edge.joins(:edge_people)
      .where(edge_people: { person_id: person.id })
      .includes(:deal, :related_person, :related_org, :created_by, { edge_people: :person })
      .by_score

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
      title: current&.title,
      linkedinUrl: person.linkedin_url,
      twitterUrl: person.twitter_url,
      instagramUrl: person.instagram_url,
      bio: person.bio,
      birthday: person.birthday,
      avatarUrl: person.avatar.attached? ? url_for(person.avatar) : person.avatar_url,
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
      relatedDeals: related_deals.map { |deal|
        {
          id: deal.id,
          name: deal.name,
          company: deal.company&.name,
          companyId: deal.company&.id,
          status: deal.status,
          role: "Referrer"
        }
      },
      relatedInterests: related_interests.map { |interest|
        role = if interest.contact_id == person.id
          "Contact"
        elsif interest.decision_maker_id == person.id
          "Decision Maker"
        else
          "Introducer"
        end
        {
          id: interest.id,
          dealId: interest.deal_id,
          dealName: interest.deal&.name,
          investor: interest.investor&.name,
          investorId: interest.investor_id,
          status: interest.status,
          role: role
        }
      },
      relatedBlocks: related_blocks.map { |block|
        role = block.contact_id == person.id ? "Seller Contact" : "Broker Contact"
        {
          id: block.id,
          dealId: block.deal_id,
          dealName: block.deal&.name,
          seller: block.seller&.name,
          sellerId: block.seller_id,
          status: block.status,
          role: role
        }
      },
      recentActivities: recent_activities.map { |activity|
        {
          id: activity.id,
          kind: activity.kind,
          subject: activity.subject,
          occurredAt: activity.occurred_at,
          startsAt: activity.starts_at,
          dealId: activity.deal_id,
          outcome: activity.outcome
        }
      },
      relationships: person_relationships.map { |rel|
        rt = rel.relationship_type
        is_source = rel.source_type == "Person" && rel.source_id == person.id
        other_type = is_source ? rel.target_type : rel.source_type
        other_id = is_source ? rel.target_id : rel.source_id
        relationship_name = is_source ? rt.name : (rt.bidirectional ? rt.name : (rt.inverse_name || rt.name))

        # Get the other entity's name
        other_name = case other_type
        when "Person"
          other_person = Person.find_by(id: other_id)
          other_person ? "#{other_person.first_name} #{other_person.last_name}" : nil
        when "Organization"
          Organization.find_by(id: other_id)&.name
        when "Deal"
          Deal.find_by(id: other_id)&.name
        else
          nil
        end

        {
          id: rel.id,
          relationshipTypeId: rt.id,
          relationshipTypeName: relationship_name,
          relationshipTypeSlug: rt.slug,
          relationshipTypeColor: rt.color,
          bidirectional: rt.bidirectional,
          otherEntityType: other_type,
          otherEntityId: other_id,
          otherEntityName: other_name,
          strength: rel.strength,
          status: rel.status,
          startedAt: rel.started_at,
          endedAt: rel.ended_at,
          notes: rel.notes
        }
      },
      edges: person_edges.map { |edge|
        edge_person = edge.edge_people.find { |ep| ep.person_id == person.id }
        {
          id: edge.id,
          title: edge.title,
          edgeType: edge.edge_type,
          confidence: edge.confidence,
          confidenceLabel: edge.confidence_label,
          timeliness: edge.timeliness,
          timelinessLabel: edge.timeliness_label,
          notes: edge.notes,
          score: edge.score,
          role: edge_person&.role,
          context: edge_person&.context,
          deal: edge.deal ? {
            id: edge.deal.id,
            name: edge.deal.name
          } : nil,
          relatedPerson: edge.related_person ? {
            id: edge.related_person.id,
            firstName: edge.related_person.first_name,
            lastName: edge.related_person.last_name
          } : nil,
          relatedOrg: edge.related_org ? {
            id: edge.related_org.id,
            name: edge.related_org.name
          } : nil,
          # Other people linked to this edge (excluding current person)
          otherPeople: edge.edge_people.reject { |ep| ep.person_id == person.id }.map { |ep|
            {
              id: ep.person.id,
              firstName: ep.person.first_name,
              lastName: ep.person.last_name,
              title: ep.person.current_title,
              organization: ep.person.current_org&.name,
              role: ep.role
            }
          },
          createdBy: edge.created_by ? {
            id: edge.created_by.id,
            firstName: edge.created_by.first_name,
            lastName: edge.created_by.last_name
          } : nil,
          createdAt: edge.created_at
        }
      },
      createdAt: person.created_at,
      updatedAt: person.updated_at
    }
  end

  def create
    person = Person.new(person_params)

    if person.save
      # Create employment if organization provided
      if params[:organizationId].present?
        Employment.create!(
          person: person,
          organization_id: params[:organizationId],
          title: params[:jobTitle],
          is_current: true,
          is_primary: true
        )
      end

      render json: { id: person.id, success: true }, status: :created
    else
      render json: { errors: person.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    person = Person.find(params[:id])

    if person.update(person_params)
      # Handle employments array if provided
      if params.key?(:employments)
        incoming_employments = params[:employments] || []
        existing_ids = person.employments.pluck(:id)
        incoming_ids = incoming_employments.map { |e| e[:id] }.compact

        # Delete employments that are no longer in the list
        ids_to_delete = existing_ids - incoming_ids
        person.employments.where(id: ids_to_delete).destroy_all

        # Create or update employments
        incoming_employments.each do |emp_params|
          if emp_params[:id].present?
            # Update existing employment
            employment = person.employments.find_by(id: emp_params[:id])
            if employment
              employment.update!(
                organization_id: emp_params[:organizationId],
                title: emp_params[:title],
                department: emp_params[:department],
                is_current: emp_params[:isCurrent],
                is_primary: emp_params[:isPrimary]
              )
            end
          else
            # Create new employment
            Employment.create!(
              person: person,
              organization_id: emp_params[:organizationId],
              title: emp_params[:title],
              department: emp_params[:department],
              is_current: emp_params[:isCurrent] != false,
              is_primary: emp_params[:isPrimary] == true
            )
          end
        end
      end

      render json: { id: person.id, success: true }
    else
      render json: { errors: person.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/people/:id/avatar
  # Handles avatar image upload
  # Expects: multipart/form-data with "avatar" file field
  def upload_avatar
    person = Person.find(params[:id])

    if params[:avatar].present?
      # Attach the uploaded file to the person's avatar
      # Rails automatically uploads it to S3 and stores the reference
      person.avatar.attach(params[:avatar])

      if person.avatar.attached?
        render json: {
          success: true,
          avatarUrl: url_for(person.avatar)
        }
      else
        render json: { errors: ["Failed to attach avatar"] }, status: :unprocessable_entity
      end
    else
      render json: { errors: ["No avatar file provided"] }, status: :unprocessable_entity
    end
  end

  # DELETE /api/people/:id/avatar
  # Removes the avatar image
  def destroy_avatar
    person = Person.find(params[:id])

    if person.avatar.attached?
      person.avatar.purge  # Deletes from S3 and removes reference
      render json: { success: true }
    else
      render json: { errors: ["No avatar to remove"] }, status: :unprocessable_entity
    end
  end

  # PATCH /api/people/bulk_update
  # Updates multiple people at once
  def bulk_update
    ids = params[:ids] || []
    updates = params[:updates] || {}

    if ids.empty?
      render json: { errors: ["No people IDs provided"] }, status: :unprocessable_entity
      return
    end

    # Map camelCase to snake_case for allowed bulk update fields
    allowed_updates = {}
    allowed_updates[:warmth] = updates[:warmth] if updates.key?(:warmth)
    allowed_updates[:source] = updates[:source] if updates.key?(:source)
    allowed_updates[:tags] = updates[:tags] if updates.key?(:tags)

    if allowed_updates.empty?
      render json: { errors: ["No valid updates provided"] }, status: :unprocessable_entity
      return
    end

    updated_count = Person.where(id: ids).update_all(allowed_updates)

    render json: { success: true, updatedCount: updated_count }
  end

  # DELETE /api/people/bulk_delete
  # Deletes multiple people at once
  def bulk_delete
    ids = params[:ids] || []

    if ids.empty?
      render json: { errors: ["No people IDs provided"] }, status: :unprocessable_entity
      return
    end

    # Delete associated records first to avoid foreign key violations
    Person.transaction do
      # Delete employments
      Employment.where(person_id: ids).destroy_all

      # Delete people
      deleted_count = Person.where(id: ids).destroy_all.count

      render json: { success: true, deletedCount: deleted_count }
    end
  rescue => e
    render json: { errors: [e.message] }, status: :unprocessable_entity
  end

  private

  def person_params
    # Map camelCase params to snake_case attributes
    {
      first_name: params[:firstName],
      last_name: params[:lastName],
      nickname: params[:nickname],
      emails: params[:emails],
      phones: params[:phones],
      linkedin_url: params[:linkedinUrl],
      twitter_url: params[:twitterUrl],
      instagram_url: params[:instagramUrl],
      bio: params[:bio],
      city: params[:city],
      state: params[:state],
      country: params[:country],
      warmth: params[:warmth] || 0,
      tags: params[:tags] || [],
      internal_notes: params[:notes],
      source: params[:source],
      source_detail: params[:sourceDetail]
    }.compact
  end
end

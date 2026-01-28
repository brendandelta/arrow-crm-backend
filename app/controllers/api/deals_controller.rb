class Api::DealsController < ApplicationController
  def index
    deals = Deal.includes(:company, :owner, :blocks, :interests, :deal_targets, :activities, :documents, :tasks).order(created_at: :desc)

    render json: deals.map { |deal|
      overdue_tasks = deal.tasks.overdue.count
      due_this_week = deal.tasks.open_tasks.due_this_week.count
      risk_flags = deal.risk_flags.present? ? deal.risk_flags : deal.compute_risk_flags

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
        owner: deal.owner ? {
          id: deal.owner.id,
          firstName: deal.owner.first_name,
          lastName: deal.owner.last_name
        } : nil,
        blocks: deal.blocks.count,
        blocksValue: deal.blocks.sum(:total_cents),
        interests: deal.interests.count,
        targets: deal.deal_targets.count,
        activeTargets: deal.deal_targets.active.count,
        committed: deal.committed_cents || 0,
        closed: deal.closed_cents || 0,
        softCircled: deal.soft_circled_cents,
        wired: deal.wired_cents,
        totalCommitted: deal.total_committed_cents,
        inventory: deal.inventory_cents,
        coverageRatio: deal.coverage_ratio,
        valuation: deal.valuation_cents,
        expectedClose: deal.expected_close,
        deadline: deal.deadline,
        daysUntilClose: deal.days_until_close,
        sourcedAt: deal.sourced_at,
        bestPrice: deal.best_price_block&.price_cents,
        overdueTasksCount: overdue_tasks,
        dueThisWeekCount: due_this_week,
        riskFlags: risk_flags,
        riskFlagsSummary: {
          count: risk_flags.values.count { |f| f.is_a?(Hash) && f[:active] },
          hasDanger: risk_flags.values.any? { |f| f.is_a?(Hash) && f[:severity] == "danger" },
          hasWarning: risk_flags.values.any? { |f| f.is_a?(Hash) && f[:severity] == "warning" }
        },
        demandFunnel: {
          prospecting: deal.interests.prospecting.count,
          contacted: deal.interests.contacted.count,
          softCircled: deal.interests.soft_circled.count,
          committed: deal.interests.committed.count,
          allocated: deal.interests.allocated.count,
          funded: deal.interests.funded.count
        },
        targetsNeedingFollowup: deal.deal_targets.active.where("last_activity_at < ? OR last_activity_at IS NULL", 7.days.ago).count
      }
    }
  end

  def stats
    deals = Deal.includes(:interests, :blocks, :tasks)

    live_deals = deals.by_status("live")
    at_risk = deals.active.select { |d| d.compute_risk_flags.values.any? { |f| f.is_a?(Hash) && f[:severity] == "danger" } }

    render json: {
      liveCount: live_deals.count,
      totalDeals: deals.count,
      activeDeals: deals.active.count,
      totalSoftCircled: live_deals.sum(&:soft_circled_cents),
      totalCommitted: live_deals.sum(&:total_committed_cents),
      totalWired: live_deals.sum(&:wired_cents),
      totalInventory: live_deals.sum(&:inventory_cents),
      atRiskCount: at_risk.count,
      overdueTasksCount: Task.open_tasks.overdue.joins(:deal).where(deals: { status: %w[sourcing live closing] }).count,
      byStatus: {
        sourcing: deals.by_status("sourcing").count,
        live: deals.by_status("live").count,
        closing: deals.by_status("closing").count,
        closed: deals.by_status("closed").count,
        dead: deals.by_status("dead").count
      }
    }
  end

  def show
    deal = Deal.includes(
      :company,
      :owner,
      :advantages,
      :documents,
      edges: [:related_person, :related_org, :created_by, { edge_people: :person }],
      blocks: [:seller, :contact, :broker, :broker_contact, :interests, { tasks: :assigned_to }],
      interests: [:investor, :contact, :decision_maker, :allocated_block, { tasks: :assigned_to }],
      deal_targets: [:target, :owner, :activities, { tasks: :assigned_to }],
      activities: [:performed_by, :assigned_to],
      tasks: [:assigned_to, :created_by, :parent_task, :subtasks]
    ).find(params[:id])

    best_block = deal.best_price_block
    next_deadline = deal.next_deadline
    biggest_constraint = deal.biggest_constraint
    risk_flags = deal.risk_flags.present? ? deal.risk_flags : deal.compute_risk_flags

    # Document checklist
    existing_doc_kinds = deal.documents.pluck(:kind).compact
    doc_checklist = Document::DILIGENCE_KINDS.map do |kind|
      {
        kind: kind,
        label: kind.titleize,
        category: Document::DILIGENCE_CATEGORIES.find { |_, kinds| kinds.include?(kind) }&.first || "Other",
        present: existing_doc_kinds.include?(kind),
        document: deal.documents.find { |d| d.kind == kind }&.then { |d|
          { id: d.id, name: d.name, url: d.url, uploadedAt: d.created_at }
        }
      }
    end

    # Missing critical doc for truth panel
    missing_doc = doc_checklist.find { |d| !d[:present] }

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
      owner: deal.owner ? {
        id: deal.owner.id,
        firstName: deal.owner.first_name,
        lastName: deal.owner.last_name,
        email: deal.owner.email
      } : nil,
      committed: deal.committed_cents || 0,
      closed: deal.closed_cents || 0,
      softCircled: deal.soft_circled_cents,
      totalCommitted: deal.total_committed_cents,
      wired: deal.wired_cents,
      inventory: deal.inventory_cents,
      coverageRatio: deal.coverage_ratio,
      target: deal.target_cents,
      valuation: deal.valuation_cents,
      sharePrice: deal.share_price_cents,
      shareClass: deal.share_class,
      expectedClose: deal.expected_close,
      deadline: deal.deadline,
      daysUntilClose: deal.days_until_close,
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

      # Truth Panel data
      truthPanel: {
        bestPrice: best_block ? {
          priceCents: best_block.price_cents,
          source: best_block.seller&.name || best_block.source,
          blockId: best_block.id
        } : nil,
        biggestConstraint: biggest_constraint,
        missingDoc: missing_doc ? {
          kind: missing_doc[:kind],
          label: missing_doc[:label]
        } : nil,
        nextDeadline: next_deadline,
        blocking: risk_flags[:deadline_risk] || risk_flags[:overdue_tasks]
      },

      # Tasks summary
      tasksSummary: deal.tasks_summary,

      # Demand funnel
      demandFunnel: deal.demand_funnel,

      # Risk flags
      riskFlags: risk_flags,

      # Document checklist
      documentChecklist: {
        total: Document::DILIGENCE_KINDS.count,
        completed: existing_doc_kinds.count { |k| Document::DILIGENCE_KINDS.include?(k) },
        completionPercent: (existing_doc_kinds.count { |k| Document::DILIGENCE_KINDS.include?(k) }.to_f / Document::DILIGENCE_KINDS.count * 100).round(0),
        items: doc_checklist
      },

      # Advantages (hidden in LP mode on frontend) - legacy, prefer edges
      advantages: deal.advantages.recent.map { |a|
        {
          id: a.id,
          kind: a.kind,
          title: a.title,
          description: a.description,
          confidence: a.confidence,
          confidenceLabel: a.confidence_label,
          timeliness: a.timeliness,
          timelinessLabel: a.timeliness_label,
          source: a.source,
          createdAt: a.created_at
        }
      },

      # Edges - unique insights/angles (hidden in LP mode on frontend)
      edges: deal.edges.by_score.map { |e|
        {
          id: e.id,
          title: e.title,
          edgeType: e.edge_type,
          confidence: e.confidence,
          confidenceLabel: e.confidence_label,
          timeliness: e.timeliness,
          timelinessLabel: e.timeliness_label,
          notes: e.notes,
          score: e.score,
          relatedPersonId: e.related_person_id,
          relatedPerson: e.related_person ? {
            id: e.related_person.id,
            firstName: e.related_person.first_name,
            lastName: e.related_person.last_name
          } : nil,
          relatedOrgId: e.related_org_id,
          relatedOrg: e.related_org ? {
            id: e.related_org.id,
            name: e.related_org.name
          } : nil,
          # People linked to this edge (with roles)
          people: e.edge_people.map { |ep|
            {
              id: ep.person.id,
              firstName: ep.person.first_name,
              lastName: ep.person.last_name,
              title: ep.person.current_title,
              organization: ep.person.current_org&.name,
              role: ep.role,
              context: ep.context
            }
          },
          createdBy: e.created_by ? {
            id: e.created_by.id,
            firstName: e.created_by.first_name,
            lastName: e.created_by.last_name
          } : nil,
          createdAt: e.created_at
        }
      },

      blocks: deal.blocks.map { |b| block_json(b, include_interests: true) },
      interests: deal.interests.map { |i| interest_json(i, include_block: true) },
      targets: deal.deal_targets.map { |t| deal_target_json(t, include_activities: true) },
      targetsSummary: {
        total: deal.deal_targets.count,
        active: deal.deal_targets.active.count,
        notStarted: deal.deal_targets.not_started.count,
        contacted: deal.deal_targets.contacted.count,
        engaged: deal.deal_targets.engaged.count,
        committed: deal.deal_targets.committed.count,
        passed: deal.deal_targets.passed.count,
        needsFollowup: deal.deal_targets.active.where("last_activity_at < ? OR last_activity_at IS NULL", 7.days.ago).count
      },

      # All activities for feed
      activities: deal.activities.recent.limit(50).map { |a| activity_json(a) },

      # Tasks grouped by status (using dedicated tasks table)
      tasks: {
        overdue: deal.tasks.overdue.by_due_date.map { |t| task_json(t) },
        dueThisWeek: deal.tasks.open_tasks.due_this_week.by_due_date.reject(&:overdue?).map { |t| task_json(t) },
        backlog: deal.tasks.open_tasks.by_due_date.reject { |t| t.overdue? || t.due_this_week? }.map { |t| task_json(t) },
        completed: deal.tasks.completed_tasks.recent.limit(10).map { |t| task_json(t) }
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

  def mind_map
    deals = Deal.where.not(status: "dead")
                .includes(:company, :owner, :blocks, :interests, :deal_targets, tasks: :assigned_to)
                .order(priority: :desc, created_at: :desc)

    groups = %w[arrow liberator].map do |owner_type|
      owner_deals = deals.select { |d| d.deal_owner == owner_type }

      {
        owner: owner_type,
        label: owner_type == "arrow" ? "Arrow Deals" : "Liberator Deals",
        deals: owner_deals.map { |deal| mind_map_deal_json(deal) }
      }
    end

    render json: { groups: groups }
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

  def mind_map_deal_json(deal)
    risk_flags = deal.risk_flags.present? ? deal.risk_flags : deal.compute_risk_flags
    risk_level = if risk_flags.values.any? { |f| f.is_a?(Hash) && f[:severity] == "danger" }
                   "danger"
                 elsif risk_flags.values.any? { |f| f.is_a?(Hash) && f[:severity] == "warning" }
                   "warning"
                 else
                   "ok"
                 end

    top_blocks = deal.blocks.sort_by { |b| -(b.heat || 0) }.first(5)
    top_interests = deal.interests.sort_by { |i| -(i.committed_cents || 0) }.first(5)
    top_targets = deal.deal_targets.active.sort_by { |t| t.priority || 99 }.first(5)

    {
      id: deal.id,
      name: deal.name,
      company: deal.company&.name,
      status: deal.status,
      priority: deal.priority,
      owner: deal.owner ? {
        id: deal.owner.id,
        firstName: deal.owner.first_name,
        lastName: deal.owner.last_name
      } : nil,
      riskLevel: risk_level,
      coverageRatio: deal.coverage_ratio,
      nextAction: compute_next_action(deal),
      blocks: top_blocks.map { |b|
        {
          id: b.id,
          name: b.seller&.name || "Block ##{b.id}",
          type: "block",
          status: b.status,
          sizeCents: b.total_cents,
          priceCents: b.price_cents,
          constraints: b.constraints,
          nextAction: compute_next_action_for_block(deal, b)
        }
      },
      interests: top_interests.map { |i|
        {
          id: i.id,
          name: i.investor&.name || "Interest ##{i.id}",
          type: "interest",
          status: i.status,
          committedCents: i.committed_cents,
          blockName: i.allocated_block&.seller&.name,
          nextAction: compute_next_action_for_interest(deal, i)
        }
      },
      targets: top_targets.map { |t|
        {
          id: t.id,
          name: t.target_name,
          type: "target",
          status: t.status,
          lastActivityAt: t.last_activity_at,
          isStale: t.last_activity_at.nil? || t.last_activity_at < 7.days.ago,
          nextAction: compute_next_action_for_target(deal, t)
        }
      }
    }
  end

  def compute_next_action(deal)
    # Find the earliest open task for this deal (any taskable or deal-level)
    all_open = deal.tasks.select { |t| !t.completed? }
    with_date = all_open.select { |t| t.due_at.present? }.sort_by(&:due_at)

    task = with_date.first || all_open.first
    if task
      is_overdue = task.due_at.present? && task.due_at < Time.current
      label = is_overdue ? "#{task.subject} (overdue)" : task.subject
      kind = task.taskable_type ? task.taskable_type.underscore.gsub("deal_", "") : "task"
      return { label: label, dueAt: task.due_at, isOverdue: is_overdue, kind: kind }
    end

    { label: "No next action set", dueAt: nil, isOverdue: false, kind: "none" }
  end

  def compute_next_action_for_block(deal, block)
    task = find_next_task_for(deal, "Block", block.id)
    return task_to_next_action(task, "task") if task

    { label: "No next action set", dueAt: nil, isOverdue: false, kind: "none" }
  end

  def compute_next_action_for_interest(deal, interest)
    task = find_next_task_for(deal, "Interest", interest.id)
    return task_to_next_action(task, "interest") if task

    { label: "No next action set", dueAt: nil, isOverdue: false, kind: "none" }
  end

  def compute_next_action_for_target(deal, target)
    task = find_next_task_for(deal, "DealTarget", target.id)
    return task_to_next_action(task, "target") if task

    { label: "No next action set", dueAt: nil, isOverdue: false, kind: "none" }
  end

  def find_next_task_for(deal, taskable_type, taskable_id)
    candidates = deal.tasks
        .select { |t| !t.completed? && t.taskable_type == taskable_type && t.taskable_id == taskable_id }
    # Prefer tasks with a due date, otherwise take any open task
    with_date = candidates.select { |t| t.due_at.present? }
    with_date.any? ? with_date.min_by(&:due_at) : candidates.first
  end

  def task_to_next_action(task, kind)
    is_overdue = task.due_at.present? && task.due_at < Time.current
    label = is_overdue ? "#{task.subject} (overdue)" : task.subject
    { label: label, dueAt: task.due_at, isOverdue: is_overdue, kind: kind }
  end

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

  def activity_json(activity)
    {
      id: activity.id,
      kind: activity.kind,
      subject: activity.subject,
      body: activity.body,
      occurredAt: activity.occurred_at,
      startsAt: activity.starts_at,
      endsAt: activity.ends_at,
      outcome: activity.outcome,
      direction: activity.direction,
      isTask: activity.is_task,
      taskCompleted: activity.task_completed,
      taskDueAt: activity.task_due_at,
      performedBy: activity.performed_by ? {
        id: activity.performed_by.id,
        firstName: activity.performed_by.first_name,
        lastName: activity.performed_by.last_name
      } : nil,
      assignedTo: activity.assigned_to ? {
        id: activity.assigned_to.id,
        firstName: activity.assigned_to.first_name,
        lastName: activity.assigned_to.last_name
      } : nil,
      createdAt: activity.created_at
    }
  end

  def task_json(task)
    {
      id: task.id,
      subject: task.subject,
      body: task.body,
      dueAt: task.due_at,
      completed: task.completed,
      overdue: task.overdue?,
      dueToday: task.due_today?,
      dueThisWeek: task.due_this_week?,
      priority: task.priority,
      priorityLabel: task.priority_label,
      status: task.status,
      isSubtask: task.subtask?,
      parentTaskId: task.parent_task_id,
      subtaskCount: task.subtask_count,
      completedSubtaskCount: task.completed_subtask_count,
      assignedTo: task.assigned_to ? {
        id: task.assigned_to.id,
        firstName: task.assigned_to.first_name,
        lastName: task.assigned_to.last_name
      } : nil,
      createdBy: task.created_by ? {
        id: task.created_by.id,
        firstName: task.created_by.first_name,
        lastName: task.created_by.last_name
      } : nil,
      dealId: task.deal_id,
      organizationId: task.organization_id,
      personId: task.person_id,
      createdAt: task.created_at,
      updatedAt: task.updated_at
    }
  end

  def block_json(block, include_interests: false)
    result = {
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
      rofr: block.rofr,
      transferApprovalRequired: block.transfer_approval_required,
      issuerApprovalRequired: block.issuer_approval_required,
      constraints: block.constraints,
      createdAt: block.created_at
    }

    # Include follow-up tasks
    open_tasks = block.tasks.select { |t| t.completed_at.nil? }.sort_by { |t| t.due_at || Time.new(9999) }
    next_task = open_tasks.first
    result[:nextTask] = if next_task
      task_data = {
        id: next_task.id,
        subject: next_task.subject,
        dueAt: next_task.due_at,
        overdue: next_task.due_at.present? && next_task.due_at < Time.current
      }
      task_data[:assignedTo] = { id: next_task.assigned_to.id, firstName: next_task.assigned_to.first_name, lastName: next_task.assigned_to.last_name } if next_task.assigned_to
      task_data
    end

    if include_interests
      result[:mappedInterests] = block.interests.map do |i|
        {
          id: i.id,
          investor: i.investor&.name,
          committedCents: i.committed_cents,
          status: i.status
        }
      end
      result[:mappedInterestsCount] = block.interests.count
      result[:mappedCommittedCents] = block.interests.sum(:committed_cents)
    end

    result
  end

  def interest_json(interest, include_block: false)
    result = {
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
      createdAt: interest.created_at,
      updatedAt: interest.updated_at,
      isStale: interest.updated_at < 7.days.ago
    }

    # Include follow-up tasks
    open_tasks = interest.tasks.select { |t| t.completed_at.nil? }.sort_by { |t| t.due_at || Time.new(9999) }
    next_task = open_tasks.first
    result[:nextTask] = if next_task
      task_data = {
        id: next_task.id,
        subject: next_task.subject,
        dueAt: next_task.due_at,
        overdue: next_task.due_at.present? && next_task.due_at < Time.current
      }
      task_data[:assignedTo] = { id: next_task.assigned_to.id, firstName: next_task.assigned_to.first_name, lastName: next_task.assigned_to.last_name } if next_task.assigned_to
      task_data
    end

    if include_block && interest.allocated_block
      result[:allocatedBlock] = {
        id: interest.allocated_block.id,
        seller: interest.allocated_block.seller&.name,
        priceCents: interest.allocated_block.price_cents,
        status: interest.allocated_block.status
      }
    end

    result
  end

  def deal_target_json(deal_target, include_activities: false)
    target = deal_target.target
    is_stale = deal_target.last_activity_at.nil? || deal_target.last_activity_at < 7.days.ago

    result = {
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
      firstContactedAt: deal_target.first_contacted_at,
      lastContactedAt: deal_target.last_contacted_at,
      lastActivityAt: deal_target.last_activity_at,
      activityCount: deal_target.activity_count,
      nextStep: deal_target.next_step,
      nextStepAt: deal_target.next_step_at,
      isStale: is_stale,
      daysSinceContact: deal_target.last_activity_at ? (Date.current - deal_target.last_activity_at.to_date).to_i : nil,
      owner: deal_target.owner ? {
        id: deal_target.owner.id,
        firstName: deal_target.owner.first_name,
        lastName: deal_target.owner.last_name
      } : nil,
      notes: deal_target.notes
    }

    # Include follow-up tasks
    open_tasks = deal_target.tasks.select { |t| t.completed_at.nil? }.sort_by { |t| t.due_at || Time.new(9999) }
    result[:tasks] = open_tasks.map do |t|
      task_data = {
        id: t.id,
        subject: t.subject,
        dueAt: t.due_at,
        overdue: t.due_at.present? && t.due_at < Time.current
      }
      task_data[:assignedTo] = { id: t.assigned_to.id, firstName: t.assigned_to.first_name, lastName: t.assigned_to.last_name } if t.assigned_to
      task_data
    end

    next_task = open_tasks.first
    result[:nextTask] = if next_task
      task_data = {
        id: next_task.id,
        subject: next_task.subject,
        dueAt: next_task.due_at,
        overdue: next_task.due_at.present? && next_task.due_at < Time.current
      }
      task_data[:assignedTo] = { id: next_task.assigned_to.id, firstName: next_task.assigned_to.first_name, lastName: next_task.assigned_to.last_name } if next_task.assigned_to
      task_data
    end

    if include_activities
      result[:recentActivities] = deal_target.activities.recent.limit(5).map do |a|
        {
          id: a.id,
          kind: a.kind,
          subject: a.subject,
          occurredAt: a.occurred_at,
          outcome: a.outcome
        }
      end
    end

    result
  end
end

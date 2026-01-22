class Task < ApplicationRecord
  # Associations
  belongs_to :parent_task, class_name: "Task", optional: true
  has_many :subtasks, class_name: "Task", foreign_key: :parent_task_id, dependent: :destroy

  belongs_to :assigned_to, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true

  # Linkable entities - tasks can be associated with any of these
  belongs_to :deal, optional: true
  belongs_to :project, optional: true
  belongs_to :organization, optional: true
  belongs_to :person, optional: true

  # Validations
  validates :subject, presence: true

  STATUSES = %w[open in_progress blocked waiting done].freeze
  validates :status, inclusion: { in: STATUSES }

  PRIORITIES = { low: 1, medium: 2, high: 3, urgent: 4 }.freeze
  validates :priority, inclusion: { in: PRIORITIES.values }

  # Scopes
  scope :open_tasks, -> { where(completed: false) }
  scope :completed_tasks, -> { where(completed: true) }
  scope :overdue, -> { where(completed: false).where("due_at < ?", Time.current) }
  scope :due_today, -> { where(due_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :due_this_week, -> { where(due_at: Time.current.beginning_of_week..Time.current.end_of_week) }
  scope :upcoming, -> { where("due_at > ?", Time.current).order(due_at: :asc) }
  scope :no_due_date, -> { where(due_at: nil) }
  scope :root_tasks, -> { where(parent_task_id: nil) }
  scope :subtasks_only, -> { where.not(parent_task_id: nil) }

  scope :assigned_to_user, ->(user) { where(assigned_to: user) }
  scope :created_by_user, ->(user) { where(created_by: user) }

  scope :for_deal, ->(deal_id) { where(deal_id: deal_id) }
  scope :for_project, ->(project_id) { where(project_id: project_id) }
  scope :for_organization, ->(org_id) { where(organization_id: org_id) }
  scope :for_person, ->(person_id) { where(person_id: person_id) }

  # Attachment type scopes
  scope :deal_tasks, -> { where.not(deal_id: nil) }
  scope :project_tasks, -> { where.not(project_id: nil) }
  scope :general_tasks, -> { where(deal_id: nil, project_id: nil) }
  scope :unassigned, -> { where(assigned_to_id: nil) }

  # Due date scopes for filtering
  scope :due_soon, -> { where(due_at: Time.current..7.days.from_now) }

  scope :by_priority, -> { order(priority: :desc, due_at: :asc) }
  scope :by_due_date, -> { order(Arel.sql("CASE WHEN due_at IS NULL THEN 1 ELSE 0 END, due_at ASC")) }
  scope :recent, -> { order(created_at: :desc) }

  # Priority helpers
  def low_priority? = priority == PRIORITIES[:low]
  def medium_priority? = priority == PRIORITIES[:medium]
  def high_priority? = priority == PRIORITIES[:high]
  def urgent? = priority == PRIORITIES[:urgent]

  def priority_label
    PRIORITIES.key(priority)&.to_s&.titleize || "Medium"
  end

  # Status helpers
  def open? = status == "open"
  def in_progress? = status == "in_progress"
  def blocked? = status == "blocked"
  def waiting? = status == "waiting"
  def done? = status == "done"

  # Due date helpers
  def overdue?
    !completed? && due_at.present? && due_at < Time.current
  end

  def due_today?
    due_at.present? && due_at.to_date == Date.current
  end

  def due_this_week?
    due_at.present? && due_at >= Time.current.beginning_of_week && due_at <= Time.current.end_of_week
  end

  # Subtask helpers
  def subtask?
    parent_task_id.present?
  end

  def root_task?
    parent_task_id.nil?
  end

  def subtask_count
    subtasks.count
  end

  def completed_subtask_count
    subtasks.completed_tasks.count
  end

  def subtask_completion_percent
    return 0 if subtask_count.zero?
    (completed_subtask_count.to_f / subtask_count * 100).round
  end

  # Complete/uncomplete
  def complete!
    update!(completed: true, completed_at: Time.current, status: "done")
  end

  def uncomplete!
    update!(completed: false, completed_at: nil, status: "open")
  end

  def toggle_completion!
    completed? ? uncomplete! : complete!
  end

  # Get the primary attachment (deal or project)
  def primary_attachment
    deal || project
  end

  def attachment_type
    return "deal" if deal_id.present?
    return "project" if project_id.present?
    "general"
  end

  def attachment_name
    primary_attachment&.name
  end

  # Get the linked entity (deal, project, organization, or person)
  def linked_entity
    deal || project || organization || person
  end

  def linked_entity_type
    return "Deal" if deal_id.present?
    return "Project" if project_id.present?
    return "Organization" if organization_id.present?
    return "Person" if person_id.present?
    nil
  end

  def linked_entity_name
    linked_entity&.name || linked_entity&.try(:full_name)
  end

  # Check attachment mode
  def deal_task?
    deal_id.present?
  end

  def project_task?
    project_id.present?
  end

  def general_task?
    deal_id.nil? && project_id.nil?
  end

  # Callbacks
  before_save :set_completed_at

  private

  def set_completed_at
    if completed_changed?
      if completed?
        self.completed_at ||= Time.current
        self.status = "done"
      else
        self.completed_at = nil
        self.status = "open" if status == "done"
      end
    end
  end
end

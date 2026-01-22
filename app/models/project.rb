class Project < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :tasks, dependent: :nullify

  # Validations
  validates :name, presence: true

  STATUSES = %w[open active paused complete].freeze
  validates :status, inclusion: { in: STATUSES }

  # Scopes
  scope :active, -> { where(status: %w[open active]) }
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(updated_at: :desc) }
  scope :alphabetical, -> { order(name: :asc) }

  # Status helpers
  def open? = status == "open"
  def active? = status == "active"
  def paused? = status == "paused"
  def complete? = status == "complete"

  # Task helpers
  def open_tasks_count
    tasks.open_tasks.count
  end

  def overdue_tasks_count
    tasks.overdue.count
  end

  def tasks_completion_percent
    total = tasks.count
    return 0 if total.zero?
    (tasks.completed_tasks.count.to_f / total * 100).round
  end
end

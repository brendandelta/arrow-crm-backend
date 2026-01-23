class MigrateNextStepsToTasks < ActiveRecord::Migration[7.2]
  def up
    # Convert DealTarget next_step/next_step_at into linked tasks
    DealTarget.where.not(next_step: [nil, ""]).find_each do |dt|
      Task.create!(
        subject: dt.next_step,
        due_at: dt.next_step_at,
        deal_id: dt.deal_id,
        taskable_type: "DealTarget",
        taskable_id: dt.id,
        priority: 2,
        status: "open",
        completed: false
      )
    end

    # Convert Interest next_step/next_step_at into linked tasks
    Interest.where.not(next_step: [nil, ""]).find_each do |interest|
      Task.create!(
        subject: interest.next_step,
        due_at: interest.next_step_at,
        deal_id: interest.deal_id,
        taskable_type: "Interest",
        taskable_id: interest.id,
        priority: 2,
        status: "open",
        completed: false
      )
    end
  end

  def down
    # Remove tasks that were created from the migration
    Task.where.not(taskable_type: nil).destroy_all
  end
end

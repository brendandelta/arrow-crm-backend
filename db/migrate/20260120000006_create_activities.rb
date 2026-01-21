class CreateActivities < ActiveRecord::Migration[7.2]
  def change
    create_table :activities do |t|
      t.string :kind, null: false  # call, email, meeting, whatsapp, sms, linkedin, note, task
      t.string :subject
      t.text :body
      t.string :direction  # inbound, outbound
      t.string :outcome  # connected, voicemail, no_answer, replied, bounced, opened, etc.
      t.datetime :occurred_at, null: false
      t.integer :duration_minutes

      # Polymorphic "regarding" - what entity is this activity about
      t.string :regarding_type, null: false  # Deal, Organization, Person, DealTarget
      t.bigint :regarding_id, null: false

      # Optional link to deal_target (for outreach tracking within deals)
      t.references :deal_target, foreign_key: true

      # Optional direct link to deal
      t.references :deal, foreign_key: true

      # Who performed the activity
      t.references :performed_by, foreign_key: { to_table: :users }

      # Additional metadata (channel-specific data, external IDs, etc.)
      t.jsonb :metadata, default: {}

      # For tasks/follow-ups
      t.boolean :is_task, default: false
      t.boolean :task_completed, default: false
      t.datetime :task_due_at
      t.references :assigned_to, foreign_key: { to_table: :users }

      t.timestamps

      t.index [:regarding_type, :regarding_id], name: "idx_activities_regarding"
      t.index :kind
      t.index :occurred_at
      t.index :is_task
      t.index [:is_task, :task_completed], name: "idx_activities_open_tasks"
    end
  end
end

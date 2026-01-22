class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks do |t|
      t.string :subject, null: false
      t.text :body
      t.datetime :due_at
      t.boolean :completed, default: false, null: false
      t.datetime :completed_at
      t.integer :priority, default: 2  # 1=low, 2=medium, 3=high, 4=urgent
      t.string :status, default: "open"  # open, in_progress, blocked, done

      # Self-referential for subtasks
      t.references :parent_task, foreign_key: { to_table: :tasks }, null: true

      # Assignment
      t.references :assigned_to, foreign_key: { to_table: :users }, null: true
      t.references :created_by, foreign_key: { to_table: :users }, null: true

      # Polymorphic linkable - tasks can belong to deals, companies, people, etc.
      # Using separate columns for cleaner queries and better indexing
      t.references :deal, foreign_key: true, null: true
      t.references :organization, foreign_key: true, null: true
      t.references :person, foreign_key: true, null: true

      # Additional metadata
      t.jsonb :metadata, default: {}

      t.timestamps

      # Indexes for common queries
      t.index :due_at
      t.index :completed
      t.index :priority
      t.index :status
      t.index [:completed, :due_at], name: "idx_tasks_open_due"
      t.index [:assigned_to_id, :completed], name: "idx_tasks_assigned_open"
    end
  end
end

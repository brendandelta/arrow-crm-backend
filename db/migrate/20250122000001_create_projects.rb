class CreateProjects < ActiveRecord::Migration[7.2]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.text :description
      t.string :status, default: "active"  # open, active, paused, complete
      t.references :owner, foreign_key: { to_table: :users }, null: true
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.jsonb :metadata, default: {}

      t.timestamps

      t.index :status
      t.index :name
    end

    # Add project_id to tasks (index is automatically created by add_reference)
    add_reference :tasks, :project, foreign_key: true, null: true, index: true
  end
end

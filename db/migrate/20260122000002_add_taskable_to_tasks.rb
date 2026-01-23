class AddTaskableToTasks < ActiveRecord::Migration[7.2]
  def change
    add_column :tasks, :taskable_type, :string
    add_column :tasks, :taskable_id, :bigint

    add_index :tasks, [:taskable_type, :taskable_id]
    add_index :tasks, [:deal_id, :taskable_type, :taskable_id]
  end
end

class CreateNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :notes do |t|
      t.text :body, null: false
      t.string :kind, default: 'note'
      t.string :parent_type, null: false
      t.bigint :parent_id, null: false
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.boolean :pinned, default: false
      t.boolean :is_private, default: false

      # Activity Tracking
      t.datetime :activity_at
      t.integer :duration_minutes
      t.string :outcome

      # Mentions
      t.bigint :mentioned_user_ids, array: true, default: []
      t.bigint :mentioned_deal_ids, array: true, default: []
      t.bigint :mentioned_org_ids, array: true, default: []
      t.bigint :mentioned_person_ids, array: true, default: []

      t.timestamps
    end

    add_index :notes, [:parent_type, :parent_id]
    add_index :notes, :pinned
    add_index :notes, :kind
    add_index :notes, :activity_at
  end
end

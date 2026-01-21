class CreateDealTargets < ActiveRecord::Migration[7.2]
  def change
    create_table :deal_targets do |t|
      t.references :deal, null: false, foreign_key: true
      t.string :target_type, null: false  # "Organization" or "Person"
      t.bigint :target_id, null: false
      t.string :status, default: "not_started", null: false
      t.string :role  # lead_investor, co_investor, advisor, etc.
      t.integer :priority, default: 2
      t.datetime :first_contacted_at
      t.datetime :last_contacted_at
      t.datetime :last_activity_at
      t.integer :activity_count, default: 0
      t.string :next_step
      t.datetime :next_step_at
      t.text :notes
      t.references :owner, foreign_key: { to_table: :users }
      t.timestamps

      t.index [:deal_id, :target_type, :target_id], unique: true, name: "idx_deal_targets_unique"
      t.index [:target_type, :target_id], name: "idx_deal_targets_target"
      t.index :status
      t.index :priority
      t.index :last_activity_at
    end
  end
end

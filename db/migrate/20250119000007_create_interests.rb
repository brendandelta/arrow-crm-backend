class CreateInterests < ActiveRecord::Migration[7.2]
  def change
    create_table :interests do |t|
      t.references :deal, null: false, foreign_key: true

      # Investor
      t.references :investor, null: false, foreign_key: { to_table: :organizations }
      t.references :contact, foreign_key: { to_table: :people }
      t.references :decision_maker, foreign_key: { to_table: :people }

      # Amounts
      t.bigint :target_cents
      t.bigint :min_cents
      t.bigint :max_cents
      t.bigint :committed_cents
      t.bigint :allocated_cents

      # Status
      t.string :status, default: 'prospecting'
      t.datetime :status_changed_at
      t.string :pass_reason
      t.text :pass_notes

      # Allocation
      t.references :allocated_block, foreign_key: { to_table: :blocks }
      t.date :wired_at
      t.bigint :wire_amount_cents

      # Source
      t.string :source
      t.string :source_detail
      t.references :introduced_by, foreign_key: { to_table: :people }

      # Tracking
      t.datetime :first_contacted_at
      t.datetime :last_contacted_at
      t.integer :meetings_count, default: 0
      t.integer :response_time_days

      # Ownership
      t.references :owner, foreign_key: { to_table: :users }

      # Meta
      t.text :notes
      t.string :next_step
      t.datetime :next_step_at

      t.timestamps
    end

    add_index :interests, :status
  end
end

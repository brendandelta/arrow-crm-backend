class CreateDeals < ActiveRecord::Migration[7.2]
  def change
    create_table :deals do |t|
      # Basic Info
      t.string :name, null: false
      t.string :kind, null: false
      t.references :company, null: false, foreign_key: { to_table: :organizations }

      # Pipeline
      t.string :status, default: 'sourcing'
      t.string :stage, default: 's1_lead'
      t.integer :priority, default: 2
      t.integer :confidence

      # Financials
      t.bigint :target_cents
      t.bigint :min_raise_cents
      t.bigint :max_raise_cents
      t.bigint :committed_cents, default: 0
      t.bigint :closed_cents, default: 0

      # Terms
      t.bigint :valuation_cents
      t.bigint :share_price_cents
      t.string :share_class
      t.text :structure_notes

      # Dates
      t.date :sourced_at
      t.date :qualified_at
      t.date :expected_close
      t.date :deadline
      t.date :closed_at

      # Source & Tracking
      t.string :source
      t.string :source_detail
      t.references :referred_by, foreign_key: { to_table: :people }
      t.references :broker, foreign_key: { to_table: :organizations }
      t.string :competitors, array: true, default: []

      # Links
      t.string :drive_url
      t.string :data_room_url
      t.string :notion_url
      t.string :deck_url

      # Ownership
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.bigint :team_member_ids, array: true, default: []

      # Meta
      t.string :tags, array: true, default: []
      t.jsonb :custom_fields, default: {}
      t.text :notes

      t.timestamps
    end

    add_index :deals, :status
    add_index :deals, :stage
    add_index :deals, :priority
    add_index :deals, :expected_close
    add_index :deals, :tags, using: :gin
  end
end

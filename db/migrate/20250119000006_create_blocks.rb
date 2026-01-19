class CreateBlocks < ActiveRecord::Migration[7.2]
  def change
    create_table :blocks do |t|
      t.references :deal, null: false, foreign_key: true

      # Seller
      t.references :seller, foreign_key: { to_table: :organizations }
      t.references :contact, foreign_key: { to_table: :people }
      t.string :seller_type

      # Shares
      t.string :share_class
      t.bigint :shares
      t.bigint :price_cents
      t.bigint :total_cents
      t.bigint :min_size_cents

      # Valuation
      t.bigint :implied_valuation_cents
      t.decimal :discount_pct, precision: 5, scale: 2
      t.date :valuation_date

      # Status
      t.string :status, default: 'available'
      t.datetime :status_changed_at
      t.date :expires_at

      # Source
      t.string :source
      t.string :source_detail
      t.references :broker, foreign_key: { to_table: :organizations }
      t.references :broker_contact, foreign_key: { to_table: :people }
      t.integer :broker_fee_bps
      t.boolean :exclusivity, default: false
      t.date :exclusivity_until

      # Verification
      t.boolean :verified, default: false
      t.datetime :verified_at
      t.text :verification_notes

      # Meta
      t.text :notes

      t.timestamps
    end

    add_index :blocks, :status
    add_index :blocks, :source
  end
end

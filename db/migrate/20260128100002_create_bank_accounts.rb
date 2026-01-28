class CreateBankAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :bank_accounts do |t|
      t.references :internal_entity, null: false, foreign_key: true

      t.string :bank_name
      t.string :account_name
      t.string :account_type, default: 'checking'

      # Encrypted routing number fields
      t.text :routing_number_ciphertext
      t.string :routing_last4

      # Encrypted account number fields
      t.text :account_number_ciphertext
      t.string :account_last4

      # Encrypted SWIFT code
      t.text :swift_ciphertext

      t.string :nickname
      t.boolean :is_primary, default: false
      t.string :status, default: 'active', null: false

      t.jsonb :metadata, default: {}

      # Audit fields
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    # Index on internal_entity_id
    add_index :bank_accounts, :internal_entity_id, name: 'idx_bank_accounts_entity'

    # Unique partial index: only one primary active account per entity
    add_index :bank_accounts, [:internal_entity_id],
              unique: true,
              where: "is_primary = true AND status = 'active'",
              name: 'idx_bank_accounts_unique_primary'

    # Index on status
    add_index :bank_accounts, :status
  end
end

class CreateCredentials < ActiveRecord::Migration[7.2]
  def change
    create_table :credentials do |t|
      t.bigint :vault_id, null: false
      t.string :title, null: false
      t.string :credential_type, null: false, default: 'login'
      t.string :url

      # Encrypted fields with last4 for masking
      t.text :username_ciphertext
      t.string :username_last4
      t.text :email_ciphertext
      t.string :email_last4
      t.text :notes_ciphertext
      t.text :secret_ciphertext
      t.string :secret_last4

      # Rotation tracking
      t.datetime :secret_last_rotated_at
      t.integer :rotation_interval_days

      # Classification
      t.string :sensitivity, default: 'confidential'

      # Flexible metadata
      t.jsonb :metadata, default: {}

      # Audit tracking
      t.bigint :created_by_id
      t.bigint :updated_by_id

      t.timestamps
    end

    add_index :credentials, :vault_id
    add_index :credentials, :credential_type
    add_index :credentials, :sensitivity
    add_index :credentials, :secret_last_rotated_at
    add_index :credentials, :metadata, using: :gin
    add_index :credentials, :created_by_id
    add_index :credentials, :updated_by_id

    add_foreign_key :credentials, :vaults
    add_foreign_key :credentials, :users, column: :created_by_id
    add_foreign_key :credentials, :users, column: :updated_by_id
  end
end

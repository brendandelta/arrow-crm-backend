class CreateCredentialFields < ActiveRecord::Migration[7.2]
  def change
    create_table :credential_fields do |t|
      t.bigint :credential_id, null: false
      t.string :label, null: false
      t.string :field_type, null: false, default: 'text'
      t.text :value_ciphertext
      t.string :value_last4
      t.boolean :is_secret, default: true
      t.integer :sort_order, default: 0

      t.timestamps
    end

    add_index :credential_fields, :credential_id
    add_index :credential_fields, [:credential_id, :sort_order]

    add_foreign_key :credential_fields, :credentials
  end
end

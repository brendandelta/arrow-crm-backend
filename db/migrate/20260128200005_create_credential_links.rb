class CreateCredentialLinks < ActiveRecord::Migration[7.2]
  def change
    create_table :credential_links do |t|
      t.bigint :credential_id, null: false
      t.string :linkable_type, null: false
      t.bigint :linkable_id, null: false
      t.string :relationship, default: 'general'
      t.bigint :created_by_id

      t.timestamps
    end

    add_index :credential_links, :credential_id
    add_index :credential_links, [:linkable_type, :linkable_id]
    add_index :credential_links, [:credential_id, :linkable_type, :linkable_id, :relationship],
              unique: true, name: 'idx_cred_links_unique'
    add_index :credential_links, :created_by_id

    add_foreign_key :credential_links, :credentials
    add_foreign_key :credential_links, :users, column: :created_by_id
  end
end

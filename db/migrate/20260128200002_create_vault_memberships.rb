class CreateVaultMemberships < ActiveRecord::Migration[7.2]
  def change
    create_table :vault_memberships do |t|
      t.bigint :vault_id, null: false
      t.bigint :user_id, null: false
      t.string :role, null: false, default: 'viewer'
      t.bigint :created_by_id

      t.timestamps
    end

    add_index :vault_memberships, :vault_id
    add_index :vault_memberships, :user_id
    add_index :vault_memberships, [:vault_id, :user_id], unique: true
    add_index :vault_memberships, :created_by_id

    add_foreign_key :vault_memberships, :vaults
    add_foreign_key :vault_memberships, :users
    add_foreign_key :vault_memberships, :users, column: :created_by_id
  end
end

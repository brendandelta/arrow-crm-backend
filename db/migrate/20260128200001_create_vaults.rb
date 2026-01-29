class CreateVaults < ActiveRecord::Migration[7.2]
  def change
    create_table :vaults do |t|
      t.string :name, null: false
      t.text :description
      t.jsonb :metadata, default: {}
      t.bigint :created_by_id

      t.timestamps
    end

    add_index :vaults, :name
    add_index :vaults, :created_by_id
    add_foreign_key :vaults, :users, column: :created_by_id
  end
end

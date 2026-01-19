class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :phone
      t.string :avatar_url
      t.string :calendar_id
      t.string :timezone, default: 'America/New_York'
      t.string :role, default: 'member'
      t.boolean :is_active, default: true
      t.datetime :last_seen_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :is_active
  end
end

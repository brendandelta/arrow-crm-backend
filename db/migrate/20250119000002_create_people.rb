class CreatePeople < ActiveRecord::Migration[7.2]
  def change
    create_table :people do |t|
      # Name
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :nickname
      t.string :prefix
      t.string :suffix

      # Contact Info
      t.jsonb :emails, default: []
      t.jsonb :phones, default: []
      t.string :preferred_contact

      # Location
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :country
      t.string :timezone

      # Professional
      t.string :title
      t.string :department
      t.string :linkedin_url
      t.string :twitter_url
      t.text :bio

      # Personal
      t.date :birthday
      t.string :avatar_url
      t.string :pronouns

      # CRM Fields
      t.string :source
      t.string :source_detail
      t.integer :warmth, default: 0
      t.references :owner, foreign_key: { to_table: :users }
      t.string :tags, array: true, default: []
      t.jsonb :custom_fields, default: {}

      # Tracking
      t.text :notes
      t.datetime :last_contacted_at
      t.datetime :next_follow_up_at
      t.integer :contact_count, default: 0

      t.timestamps
    end

    add_index :people, :warmth
    add_index :people, :tags, using: :gin
    add_index :people, :last_contacted_at
    add_index :people, [:country, :state, :city]
    add_index :people, "lower(last_name), lower(first_name)", name: "index_people_on_name_lower"
  end
end

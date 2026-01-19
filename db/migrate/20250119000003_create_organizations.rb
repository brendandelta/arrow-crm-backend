class CreateOrganizations < ActiveRecord::Migration[7.2]
  def change
    create_table :organizations do |t|
      # Basic Info
      t.string :name, null: false
      t.string :legal_name
      t.string :kind, null: false
      t.text :description
      t.string :logo_url

      # Contact Info
      t.string :website
      t.string :linkedin_url
      t.string :twitter_url
      t.string :crunchbase_url
      t.string :pitchbook_url
      t.string :phone
      t.string :email

      # Location (HQ)
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :country
      t.string :timezone

      # Classification
      t.string :sector
      t.string :sub_sector
      t.string :stage
      t.string :employee_range

      # Hierarchy
      t.references :parent_org, foreign_key: { to_table: :organizations }

      # Type-specific data
      t.jsonb :meta, default: {}

      # CRM Fields
      t.integer :warmth, default: 0
      t.references :owner, foreign_key: { to_table: :users }
      t.string :tags, array: true, default: []
      t.jsonb :custom_fields, default: {}

      # Tracking
      t.text :notes
      t.datetime :last_contacted_at
      t.datetime :next_follow_up_at

      t.timestamps
    end

    add_index :organizations, :kind
    add_index :organizations, :sector
    add_index :organizations, :warmth
    add_index :organizations, :tags, using: :gin
    add_index :organizations, [:country, :state, :city]
  end
end

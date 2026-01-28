class CreateInternalEntities < ActiveRecord::Migration[7.2]
  def change
    create_table :internal_entities do |t|
      t.string :name_legal, null: false
      t.string :name_short
      t.string :entity_type, null: false
      t.string :jurisdiction_country, default: 'US'
      t.string :jurisdiction_state
      t.date :formation_date
      t.string :status, default: 'active', null: false

      # Encrypted EIN fields
      t.text :ein_ciphertext
      t.string :ein_last4

      # Tax information
      t.string :tax_classification
      t.date :s_corp_effective_date

      # Registered agent
      t.string :registered_agent_name
      t.text :registered_agent_address

      # Addresses
      t.text :primary_address
      t.text :mailing_address

      # Notes and metadata
      t.text :notes
      t.jsonb :metadata, default: {}

      # Audit fields
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    # Functional index on lowercase name_legal for case-insensitive searches
    add_index :internal_entities, 'lower(name_legal)', name: 'index_internal_entities_on_name_legal_lower'

    # GIN index on metadata for JSONB queries
    add_index :internal_entities, :metadata, using: :gin

    # Index on status for filtering
    add_index :internal_entities, :status

    # Index on entity_type for filtering
    add_index :internal_entities, :entity_type
  end
end

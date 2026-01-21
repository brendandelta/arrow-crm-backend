class CreateRelationships < ActiveRecord::Migration[7.2]
  def change
    create_table :relationships do |t|
      # Polymorphic source (the "from" entity)
      t.string :source_type, null: false             # "Person", "Organization", "Deal", etc.
      t.bigint :source_id, null: false

      # Polymorphic target (the "to" entity)
      t.string :target_type, null: false             # "Person", "Organization", "Deal", etc.
      t.bigint :target_id, null: false

      # Relationship definition
      t.references :relationship_type, null: false, foreign_key: true

      # Relationship metadata
      t.integer :strength                            # 0-100 scale, null if not applicable
      t.string :status, default: "active"            # active, inactive, historical
      t.date :started_at                             # When relationship began
      t.date :ended_at                               # When relationship ended (if applicable)
      t.text :notes                                  # Free-form notes about the relationship
      t.jsonb :metadata, default: {}                 # Flexible additional data

      # Audit
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    # Composite indexes for efficient querying
    add_index :relationships, [:source_type, :source_id]
    add_index :relationships, [:target_type, :target_id]
    add_index :relationships, [:source_type, :source_id, :target_type, :target_id], name: "idx_relationships_source_target"
    add_index :relationships, :status
    add_index :relationships, :strength

    # Prevent duplicate relationships (same source, target, and type)
    add_index :relationships, [:source_type, :source_id, :target_type, :target_id, :relationship_type_id],
              unique: true, name: "idx_relationships_unique"
  end
end

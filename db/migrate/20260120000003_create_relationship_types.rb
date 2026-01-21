class CreateRelationshipTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :relationship_types do |t|
      t.string :name, null: false                    # Display name: "Friends", "Invested In"
      t.string :slug, null: false                    # API/code use: "friends", "invested_in"
      t.string :source_type                          # Constraint: "Person", "Organization", null = any
      t.string :target_type                          # Constraint: "Person", "Organization", null = any
      t.string :category                             # "personal", "professional", "financial", "legal", "organizational"
      t.boolean :bidirectional, default: false       # Is relationship symmetric?
      t.string :inverse_name                         # If directional, what's the reverse? "Introduced" -> "Introduced By"
      t.string :inverse_slug                         # Slug for inverse: "introduced" -> "introduced_by"
      t.text :description                            # Help text for users
      t.string :color                                # Hex color for UI badges
      t.string :icon                                 # Icon name for UI
      t.boolean :is_system, default: true            # System-defined vs user-created
      t.boolean :is_active, default: true            # Soft disable without deleting
      t.integer :sort_order, default: 0              # For UI ordering

      t.timestamps
    end

    add_index :relationship_types, :slug, unique: true
    add_index :relationship_types, [:source_type, :target_type]
    add_index :relationship_types, :category
    add_index :relationship_types, :is_active
  end
end

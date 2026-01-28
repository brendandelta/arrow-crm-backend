class CreateEntitySigners < ActiveRecord::Migration[7.2]
  def change
    create_table :entity_signers do |t|
      t.references :internal_entity, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true

      t.string :role, null: false
      t.date :effective_from
      t.date :effective_to

      t.jsonb :metadata, default: {}

      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    # Composite index for lookups
    add_index :entity_signers, [:internal_entity_id, :person_id], name: 'idx_entity_signers_entity_person'

    # Index on role for filtering
    add_index :entity_signers, :role

    # Index for finding active signers
    add_index :entity_signers, [:internal_entity_id, :effective_from, :effective_to], name: 'idx_entity_signers_active'
  end
end

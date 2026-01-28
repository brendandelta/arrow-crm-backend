class CreateDocumentLinks < ActiveRecord::Migration[7.2]
  def change
    create_table :document_links do |t|
      t.references :document, null: false, foreign_key: true

      # Polymorphic linkable (Deal, Organization, Person, InternalEntity)
      t.string :linkable_type, null: false
      t.bigint :linkable_id, null: false

      t.string :relationship, default: 'general', null: false
      t.string :visibility, default: 'default', null: false

      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    # Unique index to prevent duplicate links with same relationship
    add_index :document_links, [:document_id, :linkable_type, :linkable_id, :relationship],
              unique: true,
              name: 'idx_document_links_unique'

    # Index for polymorphic lookups
    add_index :document_links, [:linkable_type, :linkable_id],
              name: 'idx_document_links_linkable'

    # Index on relationship for filtering
    add_index :document_links, :relationship

    # Index on visibility for filtering
    add_index :document_links, :visibility
  end
end

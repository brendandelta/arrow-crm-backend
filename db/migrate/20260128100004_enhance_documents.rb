class EnhanceDocuments < ActiveRecord::Migration[7.2]
  def change
    # Rename existing 'kind' to 'doc_type' for clarity
    rename_column :documents, :kind, :doc_type

    # Add new columns to documents
    add_column :documents, :title, :string
    add_column :documents, :category, :string, null: false, default: 'other'
    add_column :documents, :status, :string, default: 'final', null: false
    add_column :documents, :source, :string, default: 'uploaded'
    add_column :documents, :sensitivity, :string, default: 'internal', null: false
    add_column :documents, :version_group_id, :uuid
    add_column :documents, :checksum, :string

    # Migrate 'name' data to 'title' where title is not set
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE documents SET title = name WHERE title IS NULL;
        SQL
      end
    end

    # Add indexes
    add_index :documents, :category
    add_index :documents, :status
    add_index :documents, :sensitivity
    add_index :documents, :version_group_id
    add_index :documents, :checksum

    # Change is_confidential default (will be replaced by sensitivity)
    # Keep is_confidential for backwards compatibility
  end
end

# frozen_string_literal: true

# Make legacy document fields nullable to support the new document linking system.
# The url, parent_type, and parent_id fields were required when documents were
# directly attached to a single parent. Now with DocumentLinks, documents can
# be linked to multiple entities, and the primary storage is via ActiveStorage.
class MakeDocumentLegacyFieldsNullable < ActiveRecord::Migration[7.2]
  def up
    # Make url nullable (ActiveStorage handles file storage now)
    change_column_null :documents, :url, true
    change_column_default :documents, :url, nil

    # Make parent_type and parent_id nullable (DocumentLinks handles relationships now)
    change_column_null :documents, :parent_type, true
    change_column_null :documents, :parent_id, true

    # Update existing records with empty url to have a placeholder
    # (This is for backwards compatibility with any existing data)
    execute <<-SQL
      UPDATE documents
      SET url = CONCAT('activestorage://', id)
      WHERE url IS NULL OR url = ''
    SQL
  end

  def down
    # Set defaults for any null values before making non-nullable
    execute <<-SQL
      UPDATE documents
      SET url = CONCAT('activestorage://', id)
      WHERE url IS NULL OR url = ''
    SQL

    execute <<-SQL
      UPDATE documents
      SET parent_type = 'Deal', parent_id = 1
      WHERE parent_type IS NULL OR parent_id IS NULL
    SQL

    change_column_null :documents, :url, false
    change_column_null :documents, :parent_type, false
    change_column_null :documents, :parent_id, false
  end
end

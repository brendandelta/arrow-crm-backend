class RenameNotesToInternalNotes < ActiveRecord::Migration[7.2]
  def change
    # Rename 'notes' column to 'internal_notes' to avoid conflict with has_many :notes association
    rename_column :organizations, :notes, :internal_notes
    rename_column :people, :notes, :internal_notes
    rename_column :deals, :notes, :internal_notes
    rename_column :blocks, :notes, :internal_notes
    rename_column :interests, :notes, :internal_notes
    # Note: meetings table doesn't have a notes column
  end
end

class AddInternalEntityBridgeToOrganizations < ActiveRecord::Migration[7.2]
  def change
    # Add bridge columns for migration from organizations to internal_entities
    add_reference :organizations, :internal_entity, foreign_key: true, null: true
    add_column :organizations, :is_internal, :boolean, default: false, null: false

    # Index for filtering internal vs external orgs
    add_index :organizations, :is_internal
  end
end

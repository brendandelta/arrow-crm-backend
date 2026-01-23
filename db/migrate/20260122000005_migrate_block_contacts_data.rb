class MigrateBlockContactsData < ActiveRecord::Migration[7.2]
  def up
    # Migrate existing contact_id to block_contacts as seller_contact
    execute <<-SQL
      INSERT INTO block_contacts (block_id, person_id, role, created_at, updated_at)
      SELECT id, contact_id, 'seller_contact', NOW(), NOW()
      FROM blocks
      WHERE contact_id IS NOT NULL
      ON CONFLICT DO NOTHING
    SQL

    # Migrate existing broker_contact_id to block_contacts as broker_contact
    execute <<-SQL
      INSERT INTO block_contacts (block_id, person_id, role, created_at, updated_at)
      SELECT id, broker_contact_id, 'broker_contact', NOW(), NOW()
      FROM blocks
      WHERE broker_contact_id IS NOT NULL
      ON CONFLICT DO NOTHING
    SQL
  end

  def down
    # Restore contact_id from block_contacts seller_contact entries
    execute <<-SQL
      UPDATE blocks
      SET contact_id = bc.person_id
      FROM block_contacts bc
      WHERE bc.block_id = blocks.id AND bc.role = 'seller_contact'
    SQL

    execute <<-SQL
      UPDATE blocks
      SET broker_contact_id = bc.person_id
      FROM block_contacts bc
      WHERE bc.block_id = blocks.id AND bc.role = 'broker_contact'
    SQL

    execute "DELETE FROM block_contacts"
  end
end

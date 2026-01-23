class CreateBlockContacts < ActiveRecord::Migration[7.2]
  def change
    create_table :block_contacts do |t|
      t.references :block, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.string :role, null: false  # seller_contact, broker_contact
      t.text :notes

      t.timestamps
    end

    add_index :block_contacts, [:block_id, :person_id, :role], unique: true
  end
end

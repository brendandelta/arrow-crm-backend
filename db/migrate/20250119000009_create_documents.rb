class CreateDocuments < ActiveRecord::Migration[7.2]
  def change
    create_table :documents do |t|
      t.string :name, null: false
      t.string :kind
      t.string :url, null: false
      t.string :file_type
      t.bigint :file_size_bytes
      t.string :storage
      t.integer :version, default: 1
      t.string :parent_type, null: false
      t.bigint :parent_id, null: false
      t.references :uploaded_by, foreign_key: { to_table: :users }
      t.text :description
      t.boolean :is_confidential, default: false
      t.date :expires_at

      t.timestamps
    end

    add_index :documents, [:parent_type, :parent_id]
    add_index :documents, :kind
  end
end

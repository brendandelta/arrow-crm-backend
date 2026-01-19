class CreateEmployments < ActiveRecord::Migration[7.2]
  def change
    create_table :employments do |t|
      t.references :person, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.string :title
      t.string :department
      t.string :seniority
      t.string :email
      t.string :phone
      t.boolean :is_primary, default: false
      t.boolean :is_current, default: true
      t.date :started_at
      t.date :ended_at
      t.text :notes

      t.timestamps
    end

    add_index :employments, [:person_id, :organization_id, :title], unique: true, name: "idx_employments_unique"
    add_index :employments, :is_current
    add_index :employments, :is_primary
  end
end

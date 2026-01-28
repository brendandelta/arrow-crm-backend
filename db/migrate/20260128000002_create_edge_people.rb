class CreateEdgePeople < ActiveRecord::Migration[7.2]
  def change
    create_table :edge_people do |t|
      t.references :edge, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.string :role  # e.g., "connector", "target", "source", "insider"
      t.text :context  # Additional context about this person's involvement

      t.timestamps

      t.index [:edge_id, :person_id], unique: true, name: "idx_edge_people_unique"
    end
  end
end

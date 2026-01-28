class CreateEdges < ActiveRecord::Migration[7.2]
  def change
    create_table :edges do |t|
      # Core relationship
      t.references :deal, null: false, foreign_key: true

      # Core fields matching frontend Edge interface
      t.string :title, null: false
      t.string :edge_type, null: false  # information, relationship, structural, timing
      t.integer :confidence, null: false, default: 3  # 1-5 scale
      t.integer :timeliness, null: false, default: 3  # 1-5 scale (freshness)
      t.text :notes

      # Optional relationships - what/who does this edge relate to?
      t.references :related_person, foreign_key: { to_table: :people }, null: true
      t.references :related_org, foreign_key: { to_table: :organizations }, null: true

      # Audit tracking
      t.references :created_by, foreign_key: { to_table: :users }, null: true

      t.timestamps

      # Indexes for common queries
      t.index :edge_type
      t.index :confidence
      t.index :timeliness
      t.index [:deal_id, :edge_type], name: "idx_edges_deal_type"
    end
  end
end

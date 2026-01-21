class CreateAdvantages < ActiveRecord::Migration[7.2]
  def change
    create_table :advantages do |t|
      t.references :deal, null: false, foreign_key: true
      t.string :kind, null: false  # pricing_edge, relationship_edge, timing_edge, information_edge
      t.string :title, null: false
      t.text :description
      t.integer :confidence  # 1-5
      t.string :timeliness   # stale, current, fresh
      t.string :source
      t.timestamps

      t.index :kind
      t.index :timeliness
    end
  end
end

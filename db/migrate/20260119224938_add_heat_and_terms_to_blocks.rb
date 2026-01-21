class AddHeatAndTermsToBlocks < ActiveRecord::Migration[7.2]
  def change
    add_column :blocks, :heat, :integer, default: 0
    add_column :blocks, :terms, :text
    add_index :blocks, :heat
  end
end

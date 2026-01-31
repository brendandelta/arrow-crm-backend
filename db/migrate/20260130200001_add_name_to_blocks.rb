class AddNameToBlocks < ActiveRecord::Migration[7.1]
  def change
    add_column :blocks, :name, :string
  end
end

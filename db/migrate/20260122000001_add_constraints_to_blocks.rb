class AddConstraintsToBlocks < ActiveRecord::Migration[7.2]
  def change
    add_column :blocks, :rofr, :boolean, default: false
    add_column :blocks, :transfer_approval_required, :boolean, default: false
    add_column :blocks, :issuer_approval_required, :boolean, default: false
  end
end

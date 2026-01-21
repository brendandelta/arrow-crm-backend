class AddDealOwnerToDeals < ActiveRecord::Migration[7.2]
  def change
    # deal_owner represents which entity owns the deal: "arrow" or "liberator"
    # This is different from owner_id which is the user managing the deal
    add_column :deals, :deal_owner, :string, default: "arrow"
    add_index :deals, :deal_owner
  end
end

class AddRiskFlagsToDeals < ActiveRecord::Migration[7.2]
  def change
    add_column :deals, :risk_flags, :jsonb, default: {}
  end
end

class AddInstagramUrlToPeople < ActiveRecord::Migration[7.2]
  def change
    add_column :people, :instagram_url, :string
  end
end

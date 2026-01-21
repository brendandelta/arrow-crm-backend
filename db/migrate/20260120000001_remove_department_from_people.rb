class RemoveDepartmentFromPeople < ActiveRecord::Migration[7.2]
  def change
    remove_column :people, :department, :string
  end
end

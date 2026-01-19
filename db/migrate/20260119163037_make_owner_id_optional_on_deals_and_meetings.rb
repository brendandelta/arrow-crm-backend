class MakeOwnerIdOptionalOnDealsAndMeetings < ActiveRecord::Migration[7.2]
  def change
    change_column_null :deals, :owner_id, true
    change_column_null :meetings, :owner_id, true
  end
end

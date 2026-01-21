class AddMeetingFieldsToActivities < ActiveRecord::Migration[7.1]
  def change
    # Add meeting/calendar-specific fields to activities
    add_column :activities, :starts_at, :datetime
    add_column :activities, :ends_at, :datetime
    add_column :activities, :location, :string
    add_column :activities, :location_type, :string  # virtual, in_person, phone
    add_column :activities, :meeting_url, :string    # Zoom/Meet/Teams link
    add_column :activities, :timezone, :string
    add_column :activities, :all_day, :boolean, default: false

    # Calendar sync fields (for future Google Calendar / Outlook integration)
    add_column :activities, :calendar_id, :string
    add_column :activities, :calendar_provider, :string  # gcal, outlook
    add_column :activities, :calendar_url, :string
    add_column :activities, :synced_at, :datetime

    # Add indexes for calendar queries
    add_index :activities, :starts_at
    add_index :activities, [:starts_at, :ends_at], name: "idx_activities_calendar_range"
    add_index :activities, :calendar_id

    # Create activity_attendees join table
    create_table :activity_attendees do |t|
      t.references :activity, null: false, foreign_key: true
      t.string :attendee_type, null: false  # "Person", "User", "external"
      t.bigint :attendee_id               # ID for Person or User
      t.string :email                      # For external attendees or as lookup
      t.string :name                       # For external attendees
      t.string :role, default: "attendee"  # organizer, attendee, optional
      t.string :response_status            # accepted, declined, tentative, needs_action
      t.boolean :is_organizer, default: false
      t.timestamps

      t.index [:activity_id, :attendee_type, :attendee_id], name: "idx_activity_attendees_unique", unique: true, where: "attendee_id IS NOT NULL"
      t.index [:activity_id, :email], name: "idx_activity_attendees_email", unique: true, where: "email IS NOT NULL"
      t.index :attendee_type
      t.index :email
    end
  end
end

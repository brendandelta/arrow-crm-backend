class CreateMeetings < ActiveRecord::Migration[7.2]
  def change
    create_table :meetings do |t|
      # Basic Info
      t.string :title, null: false
      t.text :description
      t.string :kind

      # Timing
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.string :timezone
      t.boolean :all_day, default: false
      t.boolean :is_recurring, default: false
      t.string :recurrence_rule

      # Location
      t.string :location
      t.string :location_type
      t.string :meeting_url
      t.string :dial_in
      t.string :address

      # Relationships
      t.references :deal, foreign_key: true
      t.references :organization, foreign_key: true
      t.references :owner, null: false, foreign_key: { to_table: :users }

      # Attendees
      t.bigint :attendee_ids, array: true, default: []
      t.bigint :internal_attendee_ids, array: true, default: []
      t.jsonb :external_attendees, default: []

      # Calendar Sync
      t.string :gcal_id
      t.string :gcal_url
      t.string :outlook_id
      t.datetime :synced_at

      # Content
      t.text :agenda
      t.text :summary
      t.text :action_items
      t.string :transcript_url
      t.string :recording_url

      # Follow-up
      t.string :outcome
      t.boolean :follow_up_needed, default: false
      t.date :follow_up_at
      t.text :follow_up_notes

      # Meta
      t.string :tags, array: true, default: []

      t.timestamps
    end

    add_index :meetings, :starts_at
    add_index :meetings, :attendee_ids, using: :gin
    add_index :meetings, :kind
    add_index :meetings, :gcal_id
  end
end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_01_19_163037) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "blocks", force: :cascade do |t|
    t.bigint "deal_id", null: false
    t.bigint "seller_id"
    t.bigint "contact_id"
    t.string "seller_type"
    t.string "share_class"
    t.bigint "shares"
    t.bigint "price_cents"
    t.bigint "total_cents"
    t.bigint "min_size_cents"
    t.bigint "implied_valuation_cents"
    t.decimal "discount_pct", precision: 5, scale: 2
    t.date "valuation_date"
    t.string "status", default: "available"
    t.datetime "status_changed_at"
    t.date "expires_at"
    t.string "source"
    t.string "source_detail"
    t.bigint "broker_id"
    t.bigint "broker_contact_id"
    t.integer "broker_fee_bps"
    t.boolean "exclusivity", default: false
    t.date "exclusivity_until"
    t.boolean "verified", default: false
    t.datetime "verified_at"
    t.text "verification_notes"
    t.text "internal_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["broker_contact_id"], name: "index_blocks_on_broker_contact_id"
    t.index ["broker_id"], name: "index_blocks_on_broker_id"
    t.index ["contact_id"], name: "index_blocks_on_contact_id"
    t.index ["deal_id"], name: "index_blocks_on_deal_id"
    t.index ["seller_id"], name: "index_blocks_on_seller_id"
    t.index ["source"], name: "index_blocks_on_source"
    t.index ["status"], name: "index_blocks_on_status"
  end

  create_table "deals", force: :cascade do |t|
    t.string "name", null: false
    t.string "kind", null: false
    t.bigint "company_id", null: false
    t.string "status", default: "sourcing"
    t.string "stage", default: "s1_lead"
    t.integer "priority", default: 2
    t.integer "confidence"
    t.bigint "target_cents"
    t.bigint "min_raise_cents"
    t.bigint "max_raise_cents"
    t.bigint "committed_cents", default: 0
    t.bigint "closed_cents", default: 0
    t.bigint "valuation_cents"
    t.bigint "share_price_cents"
    t.string "share_class"
    t.text "structure_notes"
    t.date "sourced_at"
    t.date "qualified_at"
    t.date "expected_close"
    t.date "deadline"
    t.date "closed_at"
    t.string "source"
    t.string "source_detail"
    t.bigint "referred_by_id"
    t.bigint "broker_id"
    t.string "competitors", default: [], array: true
    t.string "drive_url"
    t.string "data_room_url"
    t.string "notion_url"
    t.string "deck_url"
    t.bigint "owner_id"
    t.bigint "team_member_ids", default: [], array: true
    t.string "tags", default: [], array: true
    t.jsonb "custom_fields", default: {}
    t.text "internal_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["broker_id"], name: "index_deals_on_broker_id"
    t.index ["company_id"], name: "index_deals_on_company_id"
    t.index ["expected_close"], name: "index_deals_on_expected_close"
    t.index ["owner_id"], name: "index_deals_on_owner_id"
    t.index ["priority"], name: "index_deals_on_priority"
    t.index ["referred_by_id"], name: "index_deals_on_referred_by_id"
    t.index ["stage"], name: "index_deals_on_stage"
    t.index ["status"], name: "index_deals_on_status"
    t.index ["tags"], name: "index_deals_on_tags", using: :gin
  end

  create_table "documents", force: :cascade do |t|
    t.string "name", null: false
    t.string "kind"
    t.string "url", null: false
    t.string "file_type"
    t.bigint "file_size_bytes"
    t.string "storage"
    t.integer "version", default: 1
    t.string "parent_type", null: false
    t.bigint "parent_id", null: false
    t.bigint "uploaded_by_id"
    t.text "description"
    t.boolean "is_confidential", default: false
    t.date "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_documents_on_kind"
    t.index ["parent_type", "parent_id"], name: "index_documents_on_parent_type_and_parent_id"
    t.index ["uploaded_by_id"], name: "index_documents_on_uploaded_by_id"
  end

  create_table "employments", force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "organization_id", null: false
    t.string "title"
    t.string "department"
    t.string "seniority"
    t.string "email"
    t.string "phone"
    t.boolean "is_primary", default: false
    t.boolean "is_current", default: true
    t.date "started_at"
    t.date "ended_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_current"], name: "index_employments_on_is_current"
    t.index ["is_primary"], name: "index_employments_on_is_primary"
    t.index ["organization_id"], name: "index_employments_on_organization_id"
    t.index ["person_id", "organization_id", "title"], name: "idx_employments_unique", unique: true
    t.index ["person_id"], name: "index_employments_on_person_id"
  end

  create_table "interests", force: :cascade do |t|
    t.bigint "deal_id", null: false
    t.bigint "investor_id", null: false
    t.bigint "contact_id"
    t.bigint "decision_maker_id"
    t.bigint "target_cents"
    t.bigint "min_cents"
    t.bigint "max_cents"
    t.bigint "committed_cents"
    t.bigint "allocated_cents"
    t.string "status", default: "prospecting"
    t.datetime "status_changed_at"
    t.string "pass_reason"
    t.text "pass_notes"
    t.bigint "allocated_block_id"
    t.date "wired_at"
    t.bigint "wire_amount_cents"
    t.string "source"
    t.string "source_detail"
    t.bigint "introduced_by_id"
    t.datetime "first_contacted_at"
    t.datetime "last_contacted_at"
    t.integer "meetings_count", default: 0
    t.integer "response_time_days"
    t.bigint "owner_id"
    t.text "internal_notes"
    t.string "next_step"
    t.datetime "next_step_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["allocated_block_id"], name: "index_interests_on_allocated_block_id"
    t.index ["contact_id"], name: "index_interests_on_contact_id"
    t.index ["deal_id"], name: "index_interests_on_deal_id"
    t.index ["decision_maker_id"], name: "index_interests_on_decision_maker_id"
    t.index ["introduced_by_id"], name: "index_interests_on_introduced_by_id"
    t.index ["investor_id"], name: "index_interests_on_investor_id"
    t.index ["owner_id"], name: "index_interests_on_owner_id"
    t.index ["status"], name: "index_interests_on_status"
  end

  create_table "meetings", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "kind"
    t.datetime "starts_at", null: false
    t.datetime "ends_at"
    t.string "timezone"
    t.boolean "all_day", default: false
    t.boolean "is_recurring", default: false
    t.string "recurrence_rule"
    t.string "location"
    t.string "location_type"
    t.string "meeting_url"
    t.string "dial_in"
    t.string "address"
    t.bigint "deal_id"
    t.bigint "organization_id"
    t.bigint "owner_id"
    t.bigint "attendee_ids", default: [], array: true
    t.bigint "internal_attendee_ids", default: [], array: true
    t.jsonb "external_attendees", default: []
    t.string "gcal_id"
    t.string "gcal_url"
    t.string "outlook_id"
    t.datetime "synced_at"
    t.text "agenda"
    t.text "summary"
    t.text "action_items"
    t.string "transcript_url"
    t.string "recording_url"
    t.string "outcome"
    t.boolean "follow_up_needed", default: false
    t.date "follow_up_at"
    t.text "follow_up_notes"
    t.string "tags", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attendee_ids"], name: "index_meetings_on_attendee_ids", using: :gin
    t.index ["deal_id"], name: "index_meetings_on_deal_id"
    t.index ["gcal_id"], name: "index_meetings_on_gcal_id"
    t.index ["kind"], name: "index_meetings_on_kind"
    t.index ["organization_id"], name: "index_meetings_on_organization_id"
    t.index ["owner_id"], name: "index_meetings_on_owner_id"
    t.index ["starts_at"], name: "index_meetings_on_starts_at"
  end

  create_table "notes", force: :cascade do |t|
    t.text "body", null: false
    t.string "kind", default: "note"
    t.string "parent_type", null: false
    t.bigint "parent_id", null: false
    t.bigint "author_id", null: false
    t.boolean "pinned", default: false
    t.boolean "is_private", default: false
    t.datetime "activity_at"
    t.integer "duration_minutes"
    t.string "outcome"
    t.bigint "mentioned_user_ids", default: [], array: true
    t.bigint "mentioned_deal_ids", default: [], array: true
    t.bigint "mentioned_org_ids", default: [], array: true
    t.bigint "mentioned_person_ids", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_at"], name: "index_notes_on_activity_at"
    t.index ["author_id"], name: "index_notes_on_author_id"
    t.index ["kind"], name: "index_notes_on_kind"
    t.index ["parent_type", "parent_id"], name: "index_notes_on_parent_type_and_parent_id"
    t.index ["pinned"], name: "index_notes_on_pinned"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "legal_name"
    t.string "kind", null: false
    t.text "description"
    t.string "logo_url"
    t.string "website"
    t.string "linkedin_url"
    t.string "twitter_url"
    t.string "crunchbase_url"
    t.string "pitchbook_url"
    t.string "phone"
    t.string "email"
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.string "country"
    t.string "timezone"
    t.string "sector"
    t.string "sub_sector"
    t.string "stage"
    t.string "employee_range"
    t.bigint "parent_org_id"
    t.jsonb "meta", default: {}
    t.integer "warmth", default: 0
    t.bigint "owner_id"
    t.string "tags", default: [], array: true
    t.jsonb "custom_fields", default: {}
    t.text "internal_notes"
    t.datetime "last_contacted_at"
    t.datetime "next_follow_up_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country", "state", "city"], name: "index_organizations_on_country_and_state_and_city"
    t.index ["kind"], name: "index_organizations_on_kind"
    t.index ["owner_id"], name: "index_organizations_on_owner_id"
    t.index ["parent_org_id"], name: "index_organizations_on_parent_org_id"
    t.index ["sector"], name: "index_organizations_on_sector"
    t.index ["tags"], name: "index_organizations_on_tags", using: :gin
    t.index ["warmth"], name: "index_organizations_on_warmth"
  end

  create_table "people", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "nickname"
    t.string "prefix"
    t.string "suffix"
    t.jsonb "emails", default: []
    t.jsonb "phones", default: []
    t.string "preferred_contact"
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.string "country"
    t.string "timezone"
    t.string "title"
    t.string "department"
    t.string "linkedin_url"
    t.string "twitter_url"
    t.text "bio"
    t.date "birthday"
    t.string "avatar_url"
    t.string "pronouns"
    t.string "source"
    t.string "source_detail"
    t.integer "warmth", default: 0
    t.bigint "owner_id"
    t.string "tags", default: [], array: true
    t.jsonb "custom_fields", default: {}
    t.text "internal_notes"
    t.datetime "last_contacted_at"
    t.datetime "next_follow_up_at"
    t.integer "contact_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((last_name)::text), lower((first_name)::text)", name: "index_people_on_name_lower"
    t.index ["country", "state", "city"], name: "index_people_on_country_and_state_and_city"
    t.index ["last_contacted_at"], name: "index_people_on_last_contacted_at"
    t.index ["owner_id"], name: "index_people_on_owner_id"
    t.index ["tags"], name: "index_people_on_tags", using: :gin
    t.index ["warmth"], name: "index_people_on_warmth"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone"
    t.string "avatar_url"
    t.string "calendar_id"
    t.string "timezone", default: "America/New_York"
    t.string "role", default: "member"
    t.boolean "is_active", default: true
    t.datetime "last_seen_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["is_active"], name: "index_users_on_is_active"
  end

  add_foreign_key "blocks", "deals"
  add_foreign_key "blocks", "organizations", column: "broker_id"
  add_foreign_key "blocks", "organizations", column: "seller_id"
  add_foreign_key "blocks", "people", column: "broker_contact_id"
  add_foreign_key "blocks", "people", column: "contact_id"
  add_foreign_key "deals", "organizations", column: "broker_id"
  add_foreign_key "deals", "organizations", column: "company_id"
  add_foreign_key "deals", "people", column: "referred_by_id"
  add_foreign_key "deals", "users", column: "owner_id"
  add_foreign_key "documents", "users", column: "uploaded_by_id"
  add_foreign_key "employments", "organizations"
  add_foreign_key "employments", "people"
  add_foreign_key "interests", "blocks", column: "allocated_block_id"
  add_foreign_key "interests", "deals"
  add_foreign_key "interests", "organizations", column: "investor_id"
  add_foreign_key "interests", "people", column: "contact_id"
  add_foreign_key "interests", "people", column: "decision_maker_id"
  add_foreign_key "interests", "people", column: "introduced_by_id"
  add_foreign_key "interests", "users", column: "owner_id"
  add_foreign_key "meetings", "deals"
  add_foreign_key "meetings", "organizations"
  add_foreign_key "meetings", "users", column: "owner_id"
  add_foreign_key "notes", "users", column: "author_id"
  add_foreign_key "organizations", "organizations", column: "parent_org_id"
  add_foreign_key "organizations", "users", column: "owner_id"
  add_foreign_key "people", "users", column: "owner_id"
end

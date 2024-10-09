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

ActiveRecord::Schema[8.0].define(version: 2024_08_14_192200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "comments", id: :serial, force: :cascade do |t|
    t.integer "type_id", null: false
    t.integer "reference_id", null: false
    t.integer "comment_id"
    t.text "content"
    t.integer "creator_id", null: false
    t.integer "updator_id", null: false
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.string "name", limit: 512, null: false
    t.text "content"
    t.string "location"
    t.integer "group_id", null: false
    t.timestamptz "when", null: false
    t.timestamptz "send_invitation_at"
    t.integer "required_people"
    t.timestamptz "send_cancellation_at"
    t.integer "next_event"
    t.integer "status_id", null: false
    t.integer "creator_id", null: false
    t.integer "updator_id", null: false
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.timestamptz "until"
    t.integer "team_id", null: false
    t.boolean "allow_tentative_selection", default: false, null: false
  end

  create_table "groups", id: :serial, force: :cascade do |t|
    t.string "name", limit: 512, null: false
    t.text "note"
    t.integer "creator_id", null: false
    t.integer "updator_id", null: false
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["name"], name: "index_groups_on_name", unique: true
  end

  create_table "holidays", id: :serial, force: :cascade do |t|
    t.string "name", limit: 512, null: false
    t.date "from", null: false
    t.date "to", null: false
    t.integer "creator_id", null: false
    t.integer "updator_id", null: false
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["from"], name: "index_holidays_on_from"
    t.index ["name"], name: "index_holidays_on_name", unique: true
  end

  create_table "invitees", id: :serial, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "event_id", null: false
    t.integer "status_id", null: false
    t.string "invitation_key", limit: 512
    t.timestamptz "invitation_sent"
    t.string "invitation_sent_error", limit: 1024
    t.integer "invitation_sent_retry"
    t.timestamptz "last_response_at"
    t.integer "creator_id", null: false
    t.integer "updator_id", null: false
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.integer "guest"
    t.index ["invitation_key"], name: "index_invitees_on_invitation_key", unique: true
    t.index ["person_id", "event_id"], name: "index_invitees_on_person_id_and_event_id", unique: true
  end

  create_table "members", id: :serial, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "group_id", null: false
    t.integer "creator_id", null: false
    t.timestamptz "created_at", null: false
    t.index ["person_id", "group_id"], name: "index_members_on_person_id_and_group_id", unique: true
  end

  create_table "people", id: :serial, force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "nick_name", null: false
    t.string "email", limit: 512
    t.string "auth_token", null: false
    t.string "password_digest", limit: 512
    t.string "password_reset_token"
    t.timestamptz "password_reset_sent_at"
    t.string "roles", limit: 512
    t.integer "status_id", null: false
    t.integer "creator_id", null: false
    t.integer "updator_id", null: false
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["email"], name: "index_people_on_email", unique: true
    t.index ["nick_name"], name: "index_people_on_nick_name", unique: true
  end

  create_table "spider_tracking", force: :cascade do |t|
    t.string "ip", limit: 128
    t.string "person", limit: 512
    t.text "url"
    t.text "agent"
    t.timestamptz "created_at", default: -> { "now()" }, null: false
  end

  create_table "statuses", id: :serial, force: :cascade do |t|
    t.integer "type_id", null: false
    t.string "name", null: false
    t.text "note"
    t.integer "creator_id", null: false
    t.integer "updator_id", null: false
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["type_id", "name"], name: "index_statuses_on_type_id_and_name", unique: true
  end

  create_table "teams", id: :serial, force: :cascade do |t|
    t.string "name", limit: 512, null: false
    t.integer "type_id", null: false
    t.text "note"
    t.integer "creator_id", null: false
    t.integer "updator_id", null: false
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["name"], name: "index_teams_on_name", unique: true
  end

  create_table "types", id: :serial, force: :cascade do |t|
    t.string "type_type", null: false
    t.string "name", null: false
    t.integer "creator_id", null: false
    t.integer "updator_id", null: false
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["type_type", "name"], name: "index_types_on_type_type_and_name", unique: true
  end

  add_foreign_key "comments", "types", name: "comments_type_id_fkey"
  add_foreign_key "events", "groups", name: "events_group_id_fkey"
  add_foreign_key "events", "people", column: "creator_id", name: "events_creator_id_fkey"
  add_foreign_key "events", "people", column: "updator_id", name: "events_updator_id_fkey"
  add_foreign_key "events", "statuses", name: "events_status_id_fkey"
  add_foreign_key "events", "teams", name: "events_team_id_fkey"
  add_foreign_key "groups", "people", column: "creator_id", name: "groups_creator_id_fkey"
  add_foreign_key "groups", "people", column: "updator_id", name: "groups_updator_id_fkey"
  add_foreign_key "holidays", "people", column: "creator_id", name: "holidays_creator_id_fkey"
  add_foreign_key "holidays", "people", column: "updator_id", name: "holidays_updator_id_fkey"
  add_foreign_key "invitees", "events", name: "invitees_event_id_fkey", on_delete: :cascade
  add_foreign_key "invitees", "people", column: "creator_id", name: "invitees_creator_id_fkey", on_delete: :cascade
  add_foreign_key "invitees", "people", column: "creator_id", name: "invitees_creator_id_fkey1"
  add_foreign_key "invitees", "people", column: "updator_id", name: "invitees_updator_id_fkey", on_delete: :cascade
  add_foreign_key "invitees", "people", column: "updator_id", name: "invitees_updator_id_fkey1"
  add_foreign_key "invitees", "people", name: "invitees_person_id_fkey", on_delete: :cascade
  add_foreign_key "invitees", "statuses", name: "invitees_status_id_fkey"
  add_foreign_key "members", "groups", name: "members_group_id_fkey", on_delete: :cascade
  add_foreign_key "members", "people", column: "creator_id", name: "members_creator_id_fkey", on_delete: :cascade
  add_foreign_key "members", "people", column: "creator_id", name: "members_creator_id_fkey1"
  add_foreign_key "members", "people", name: "members_person_id_fkey", on_delete: :cascade
  add_foreign_key "people", "people", column: "creator_id", name: "people_creator_id_fkey"
  add_foreign_key "people", "people", column: "updator_id", name: "people_updator_id_fkey"
  add_foreign_key "people", "statuses", name: "people_status_id_fkey"
  add_foreign_key "statuses", "people", column: "creator_id", name: "statuses_creator_id_fkey"
  add_foreign_key "statuses", "people", column: "updator_id", name: "statuses_updator_id_fkey"
  add_foreign_key "statuses", "types", name: "statuses_type_id_fkey"
  add_foreign_key "teams", "people", column: "creator_id", name: "teams_creator_id_fkey"
  add_foreign_key "teams", "people", column: "updator_id", name: "teams_updator_id_fkey"
  add_foreign_key "teams", "types", name: "teams_type_id_fkey"
  add_foreign_key "types", "people", column: "creator_id", name: "types_creator_id_fkey"
  add_foreign_key "types", "people", column: "updator_id", name: "types_updator_id_fkey"
end

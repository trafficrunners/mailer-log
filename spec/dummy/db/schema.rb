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

ActiveRecord::Schema[7.2].define(version: 2024_12_14_000004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "mailer_log_emails", force: :cascade do |t|
    t.string "tracking_id", null: false
    t.string "message_id"
    t.string "mailer_class"
    t.string "mailer_action"
    t.string "from_address"
    t.string "to_addresses", default: [], array: true
    t.string "cc_addresses", default: [], array: true
    t.string "bcc_addresses", default: [], array: true
    t.string "subject"
    t.text "html_body"
    t.text "text_body"
    t.jsonb "headers", default: {}
    t.text "call_stack", default: [], array: true
    t.string "git_revision"
    t.string "domain"
    t.string "status", default: "pending"
    t.string "accountable_type"
    t.bigint "accountable_id"
    t.datetime "delivered_at"
    t.datetime "opened_at"
    t.datetime "clicked_at"
    t.datetime "bounced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["accountable_type", "accountable_id"], name: "index_mailer_log_emails_on_accountable"
    t.index ["created_at"], name: "index_mailer_log_emails_on_created_at"
    t.index ["from_address"], name: "index_mailer_log_emails_on_from_address"
    t.index ["mailer_class"], name: "index_mailer_log_emails_on_mailer_class"
    t.index ["message_id"], name: "index_mailer_log_emails_on_message_id"
    t.index ["status"], name: "index_mailer_log_emails_on_status"
    t.index ["to_addresses"], name: "index_mailer_log_emails_on_to_addresses", using: :gin
    t.index ["tracking_id"], name: "index_mailer_log_emails_on_tracking_id", unique: true
  end

  create_table "mailer_log_events", force: :cascade do |t|
    t.bigint "email_id", null: false
    t.string "event_type", null: false
    t.string "recipient"
    t.string "mailgun_event_id"
    t.datetime "occurred_at"
    t.string "ip_address"
    t.string "user_agent"
    t.string "device_type"
    t.string "client_name"
    t.string "client_os"
    t.string "country"
    t.string "region"
    t.string "city"
    t.string "url"
    t.jsonb "raw_payload", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_id"], name: "index_mailer_log_events_on_email_id"
    t.index ["event_type"], name: "index_mailer_log_events_on_event_type"
    t.index ["mailgun_event_id"], name: "index_mailer_log_events_on_mailgun_event_id", unique: true
    t.index ["occurred_at"], name: "index_mailer_log_events_on_occurred_at"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.bigint "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
  end

  add_foreign_key "mailer_log_events", "mailer_log_emails", column: "email_id"
  add_foreign_key "users", "organizations"
end

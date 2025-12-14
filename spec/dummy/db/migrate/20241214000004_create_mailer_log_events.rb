# frozen_string_literal: true

class CreateMailerLogEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :mailer_log_events do |t|
      t.references :email, null: false, foreign_key: { to_table: :mailer_log_emails }
      t.string :event_type, null: false
      t.string :recipient
      t.string :mailgun_event_id
      t.datetime :occurred_at
      t.string :ip_address
      t.string :user_agent
      t.string :device_type
      t.string :client_name
      t.string :client_os
      t.string :country
      t.string :region
      t.string :city
      t.string :url
      t.jsonb :raw_payload, default: {}

      t.timestamps
    end

    add_index :mailer_log_events, :event_type
    add_index :mailer_log_events, :mailgun_event_id, unique: true
    add_index :mailer_log_events, :occurred_at
  end
end

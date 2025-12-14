# frozen_string_literal: true

class CreateMailerLogEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :mailer_log_events do |t|
      t.references :email, null: false, foreign_key: { to_table: :mailer_log_emails }, index: true

      t.string :event_type, null: false
      t.string :mailgun_event_id
      t.datetime :occurred_at
      t.string :recipient
      t.string :ip_address
      t.string :user_agent
      t.jsonb :raw_data, default: {}

      t.timestamps
    end

    add_index :mailer_log_events, :event_type
    add_index :mailer_log_events, :mailgun_event_id, unique: true
    add_index :mailer_log_events, :occurred_at
  end
end

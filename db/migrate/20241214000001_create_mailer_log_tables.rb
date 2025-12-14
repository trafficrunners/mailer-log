# frozen_string_literal: true

class CreateMailerLogTables < ActiveRecord::Migration[7.1]
  def change
    create_table :mailer_log_emails do |t|
      t.string :message_id
      t.uuid :tracking_id, null: false
      t.string :mailer_class
      t.string :mailer_action
      t.string :from_address
      t.string :to_addresses, array: true, default: []
      t.string :cc_addresses, array: true, default: []
      t.string :bcc_addresses, array: true, default: []
      t.string :subject
      t.text :html_body
      t.text :text_body
      t.jsonb :headers, default: {}
      t.text :call_stack
      t.string :domain
      t.references :accountable, polymorphic: true, index: true
      t.string :status, null: false, default: 'pending'
      t.datetime :delivered_at
      t.datetime :opened_at
      t.datetime :clicked_at
      t.datetime :bounced_at
      t.timestamps
    end

    add_index :mailer_log_emails, :tracking_id, unique: true
    add_index :mailer_log_emails, :message_id, unique: true
    add_index :mailer_log_emails, :mailer_class
    add_index :mailer_log_emails, :status
    add_index :mailer_log_emails, :to_addresses, using: :gin
    add_index :mailer_log_emails, :created_at

    create_table :mailer_log_events do |t|
      t.references :email, null: false, foreign_key: { to_table: :mailer_log_emails }
      t.string :event_type, null: false
      t.string :mailgun_event_id
      t.datetime :occurred_at
      t.string :recipient
      t.string :ip_address
      t.string :user_agent
      t.jsonb :raw_data, default: {}
      t.timestamps
    end

    add_index :mailer_log_events, :mailgun_event_id, unique: true
    add_index :mailer_log_events, :event_type
    add_index :mailer_log_events, :occurred_at
  end
end

# frozen_string_literal: true

class CreateMailerLogEmails < ActiveRecord::Migration[7.0]
  def change
    create_table :mailer_log_emails do |t|
      t.string :tracking_id, null: false
      t.string :message_id
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
      t.text :call_stack, array: true, default: []
      t.string :domain
      t.string :status, default: 'pending'
      t.references :accountable, polymorphic: true

      t.datetime :delivered_at
      t.datetime :opened_at
      t.datetime :clicked_at
      t.datetime :bounced_at

      t.timestamps
    end

    add_index :mailer_log_emails, :tracking_id, unique: true
    add_index :mailer_log_emails, :message_id
    add_index :mailer_log_emails, :status
    add_index :mailer_log_emails, :mailer_class
    add_index :mailer_log_emails, :from_address
    add_index :mailer_log_emails, :created_at
    add_index :mailer_log_emails, :to_addresses, using: :gin
  end
end

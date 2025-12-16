# frozen_string_literal: true

module MailerLog
  class Event < ApplicationRecord
    self.table_name = 'mailer_log_events'

    enum :event_type, {
      accepted: 'accepted',
      delivered: 'delivered',
      opened: 'opened',
      clicked: 'clicked',
      bounced: 'bounced',
      failed: 'failed',
      dropped: 'dropped',
      complained: 'complained',
      unsubscribed: 'unsubscribed'
    }

    # Store accessors for raw_payload jsonb column
    store_accessor :raw_payload,
      :event,
      :tags,
      :campaigns,
      :client_info,
      :geolocation,
      :delivery_status,
      :envelope,
      :message,
      :flags,
      :severity,
      :reason,
      :log_level

    belongs_to :email, class_name: 'MailerLog::Email', inverse_of: :events

    validates :event_type, presence: true
    validates :mailgun_event_id, uniqueness: true, allow_nil: true

    scope :recent, -> { order(occurred_at: :desc) }

    # Convenience methods for delivery_status
    def delivery_code
      delivery_status&.dig('code')
    end

    def delivery_message
      delivery_status&.dig('message')
    end

    def tls?
      !!delivery_status&.dig('tls')
    end
  end
end

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

    belongs_to :email, class_name: 'MailerLog::Email', inverse_of: :events

    validates :event_type, presence: true
    validates :mailgun_event_id, uniqueness: true, allow_nil: true

    scope :recent, -> { order(occurred_at: :desc) }
  end
end

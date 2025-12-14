# frozen_string_literal: true

module MailerLog
  class Event < ApplicationRecord
    self.table_name = 'mailer_log_events'

    EVENT_TYPES = %w[
      accepted
      delivered
      opened
      clicked
      bounced
      failed
      dropped
      complained
      unsubscribed
    ].freeze

    belongs_to :email, class_name: 'MailerLog::Email', inverse_of: :events

    validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
    validates :mailgun_event_id, uniqueness: true, allow_nil: true

    scope :by_type, ->(type) { where(event_type: type) }
    scope :recent, -> { order(occurred_at: :desc) }
  end
end

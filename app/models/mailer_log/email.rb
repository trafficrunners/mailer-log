# frozen_string_literal: true

module MailerLog
  class Email < ApplicationRecord
    self.table_name = 'mailer_log_emails'

    STATUSES = %w[pending sent delivered opened clicked bounced complained].freeze

    has_many :events, class_name: 'MailerLog::Event', dependent: :delete_all

    belongs_to :accountable, polymorphic: true, optional: true

    validates :tracking_id, presence: true, uniqueness: true
    validates :status, inclusion: { in: STATUSES }

    scope :by_status, ->(status) { where(status: status) }
    scope :by_mailer, ->(mailer_class) { where(mailer_class: mailer_class) }
    scope :recent, -> { order(created_at: :desc) }

    # Scopes for filtering
    scope :recipient, ->(val) { where("array_to_string(to_addresses, ',') ILIKE ?", "%#{val}%") }
    scope :sender, ->(val) { where('from_address ILIKE ?', "%#{val}%") }
    scope :subject_search, ->(val) { where('subject ILIKE ?', "%#{val}%") }
    scope :mailer, ->(val) { where(mailer_class: val) }
    scope :date_from, ->(date) { where(created_at: date.to_date.beginning_of_day..) }
    scope :date_to, ->(date) { where(created_at: ..date.to_date.end_of_day) }

    def update_status_from_event!(event_type)
      case event_type
      when 'delivered'
        update!(status: 'delivered', delivered_at: Time.current) unless opened_at? || clicked_at?
      when 'opened'
        update!(status: 'opened', opened_at: Time.current) unless clicked_at?
      when 'clicked'
        update!(status: 'clicked', clicked_at: Time.current)
      when 'bounced', 'failed', 'dropped'
        update!(status: 'bounced', bounced_at: Time.current)
      when 'complained'
        update!(status: 'complained')
      end
    end

    def recipients
      (to_addresses + cc_addresses + bcc_addresses).compact.uniq
    end
  end
end

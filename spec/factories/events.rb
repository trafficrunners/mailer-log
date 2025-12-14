# frozen_string_literal: true

FactoryBot.define do
  factory :mailer_log_event, class: 'MailerLog::Event' do
    association :email, factory: :mailer_log_email
    event_type { 'delivered' }
    sequence(:mailgun_event_id) { SecureRandom.hex(16) }
    occurred_at { Time.current }
    sequence(:recipient) { |n| "user-#{n}@example.com" }
    ip_address { '192.168.1.1' }
    user_agent { 'Mozilla/5.0' }
    raw_payload { { 'event' => 'delivered', 'timestamp' => Time.current.to_i } }

    trait :opened do
      event_type { 'opened' }
    end

    trait :clicked do
      event_type { 'clicked' }
    end

    trait :bounced do
      event_type { 'bounced' }
    end
  end
end

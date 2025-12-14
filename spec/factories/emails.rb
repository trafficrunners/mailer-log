# frozen_string_literal: true

FactoryBot.define do
  factory :mailer_log_email, class: 'MailerLog::Email' do
    tracking_id { SecureRandom.uuid }
    sequence(:message_id) { |n| "<msg-#{n}-#{SecureRandom.hex(8)}@mail.example.com>" }
    mailer_class { 'UsersMailer' }
    mailer_action { 'welcome' }
    from_address { 'noreply@example.com' }
    to_addresses { ["user-#{SecureRandom.hex(4)}@example.com"] }
    cc_addresses { [] }
    bcc_addresses { [] }
    subject { "Test Email #{SecureRandom.hex(4)}" }
    html_body { '<html><body><h1>Hello</h1></body></html>' }
    text_body { 'Hello' }
    headers { { 'X-Mailer' => 'ActionMailer' } }
    call_stack { nil }
    domain { 'example.com' }
    status { 'sent' }
    delivered_at { nil }
    opened_at { nil }
    clicked_at { nil }
    bounced_at { nil }

    trait :delivered do
      status { 'delivered' }
      delivered_at { Time.current }
    end

    trait :bounced do
      status { 'bounced' }
      bounced_at { Time.current }
    end

    trait :opened do
      status { 'opened' }
      delivered_at { 1.hour.ago }
      opened_at { Time.current }
    end

    trait :with_call_stack do
      call_stack { ['/app/controllers/users_controller.rb:25', '/app/services/mailer_service.rb:10'] }
    end
  end
end

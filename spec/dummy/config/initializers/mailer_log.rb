# frozen_string_literal: true

MailerLog.configure do |config|
  config.retention_period = 1.year
  config.capture_call_stack = true
  config.call_stack_depth = 20
end

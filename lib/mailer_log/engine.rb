# frozen_string_literal: true

require 'mailer_log/mail_interceptor'
require 'mailer_log/mail_observer'

module MailerLog
  class Engine < ::Rails::Engine
    isolate_namespace MailerLog

    initializer 'mailer_log.action_mailer' do
      ActiveSupport.on_load(:action_mailer) do
        ActionMailer::Base.register_interceptor(MailerLog::MailInterceptor)
        ActionMailer::Base.register_observer(MailerLog::MailObserver)
      end
    end

    # Subscribe to process.action_mailer to capture mailer action before delivery
    initializer 'mailer_log.notifications' do
      ActiveSupport::Notifications.subscribe('process.action_mailer') do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        MailerLog::Current.mailer_action = event.payload[:action]
        MailerLog::Current.mailer_class = event.payload[:mailer]
      end
    end

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end

    # Load rake tasks
    rake_tasks do
      load MailerLog::Engine.root.join('lib', 'tasks', 'mailer_log.rake')
    end
  end
end

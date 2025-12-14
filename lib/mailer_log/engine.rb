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

    initializer 'mailer_log.append_migrations' do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths['db/migrate'].expanded.each do |path|
          app.config.paths['db/migrate'] << path
        end
      end
    end

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end
  end
end

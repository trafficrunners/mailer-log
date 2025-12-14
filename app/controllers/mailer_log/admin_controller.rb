# frozen_string_literal: true

module MailerLog
  class AdminController < ::AdminsController
    prepend HasScope

    # Expose main app routes to views
    helper Rails.application.routes.url_helpers

    before_action :authenticate_mailer_log!

    private

    def authenticate_mailer_log!
      return unless MailerLog.configuration.authenticate_with_proc

      MailerLog.configuration.authenticate_with_proc.call(self)
    end

    def mailer_log_engine
      MailerLog::Engine.routes.url_helpers
    end
    helper_method :mailer_log_engine
  end
end

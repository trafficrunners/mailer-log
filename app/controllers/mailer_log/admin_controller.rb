# frozen_string_literal: true

module MailerLog
  class AdminController < ::AdminsController
    prepend HasScope

    # Expose main app routes to views for navbar/layout links
    helper Rails.application.routes.url_helpers

    before_action :authenticate_mailer_log!

    # Make main_app proxy available in views
    helper_method :main_app

    # Override url_options to prevent main app routes from being prefixed
    # with the engine's mount path
    def url_options
      script_name = request.env['SCRIPT_NAME']
      return super unless script_name&.include?('mailer_log') || script_name&.include?('email_log')

      super.merge(script_name: '')
    end

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

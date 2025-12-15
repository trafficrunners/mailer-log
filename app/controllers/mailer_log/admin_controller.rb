# frozen_string_literal: true

module MailerLog
  class AdminController < ::AdminsController
    helper Rails.application.routes.url_helpers

    before_action :authenticate_mailer_log!

    private

    def authenticate_mailer_log!
      return unless MailerLog.configuration.authenticate_with_proc

      MailerLog.configuration.authenticate_with_proc.call(self)
    end
  end
end

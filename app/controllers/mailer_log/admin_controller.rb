# frozen_string_literal: true

module MailerLog
  class AdminController < ::AdminsController
    # Make main app routes available in views (for header_partial)
    helper Rails.application.routes.url_helpers

    before_action :authenticate_mailer_log!

    rescue_from 'Pundit::NotAuthorizedError', with: :render_not_found

    private

    def authenticate_mailer_log!
      return unless MailerLog.configuration.authenticate_with_proc

      MailerLog.configuration.authenticate_with_proc.call(self)
    end

    def render_not_found
      raise ActionController::RoutingError, 'Not Found'
    end
  end
end

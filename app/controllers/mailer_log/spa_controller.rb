# frozen_string_literal: true

module MailerLog
  class SpaController < MailerLog::AdminController
    helper MailerLog::SpaHelper
    helper Rails.application.helpers

    layout -> { MailerLog.configuration.spa_layout || false }

    def index
      render :index
    end
  end
end

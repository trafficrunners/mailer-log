# frozen_string_literal: true

module MailerLog
  class SpaController < MailerLog::AdminController
    helper MailerLog::SpaHelper

    layout false

    def index
      render :index
    end
  end
end

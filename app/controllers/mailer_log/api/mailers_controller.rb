# frozen_string_literal: true

module MailerLog
  module Api
    class MailersController < MailerLog::AdminController
      skip_before_action :verify_authenticity_token

      def index
        mailers = MailerLog::Email.distinct.pluck(:mailer_class).compact.sort

        render json: { mailers: mailers }
      end
    end
  end
end

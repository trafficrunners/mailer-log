# frozen_string_literal: true

module MailerLog
  class MailObserver
    class << self
      def delivered_email(message)
        data = MailerLog::Current.email_data
        return unless data

        email = MailerLog::Email.new(
          data.merge(
            message_id: message.message_id,
            status: 'sent'
          )
        )

        # Resolve accountable via configured resolver
        resolve_accountable(email)

        email.save!
      rescue StandardError => e
        Rails.logger.error("MailerLog::MailObserver error: #{e.message}")
        Rails.logger.error(e.backtrace.first(5).join("\n"))
        report_error(e)
      ensure
        MailerLog::Current.reset
      end

      private

      def resolve_accountable(email)
        resolver = MailerLog.configuration.resolve_accountable_proc
        return unless resolver

        email.accountable = resolver.call(email)
      rescue StandardError => e
        Rails.logger.warn("MailerLog: Failed to resolve accountable: #{e.message}")
      end

      def report_error(exception)
        Airbrake.notify(exception) if defined?(Airbrake)
      end
    end
  end
end

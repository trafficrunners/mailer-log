# frozen_string_literal: true

module MailerLog
  class MailInterceptor
    class << self
      def delivering_email(message)
        tracking_id = SecureRandom.uuid

        # Add tracking header for Mailgun webhook correlation
        message.header['X-Mailer-Log-Tracking-ID'] = tracking_id

        # Store data for observer to pick up after delivery
        MailerLog::Current.email_data = {
          tracking_id: tracking_id,
          mailer_class: extract_mailer_class(message),
          mailer_action: extract_mailer_action(message),
          from_address: message.from&.first,
          to_addresses: Array(message.to),
          cc_addresses: Array(message.cc),
          bcc_addresses: Array(message.bcc),
          subject: message.subject,
          html_body: extract_html_body(message),
          text_body: extract_text_body(message),
          headers: extract_headers(message),
          call_stack: capture_call_stack,
          domain: message[:domain]&.value
        }
      rescue StandardError => e
        Rails.logger.error("MailerLog::MailInterceptor error: #{e.message}")
        Rails.logger.error(e.backtrace.first(5).join("\n"))
      end

      private

      def extract_mailer_class(message)
        handler = message.delivery_handler
        return message['X-Mailer']&.to_s || 'Unknown' unless handler

        handler.is_a?(Class) ? handler.name : handler.class.name
      end

      def extract_mailer_action(message)
        # First, try to get from Current (set by process.action_mailer notification)
        return MailerLog::Current.mailer_action if MailerLog::Current.mailer_action.present?

        handler = message.delivery_handler
        return 'unknown' unless handler

        if handler.respond_to?(:action_name) && !handler.is_a?(Class)
          handler.action_name.to_s
        elsif message['X-Mailer-Action']
          message['X-Mailer-Action'].to_s
        else
          'unknown'
        end
      end

      def extract_html_body(message)
        if message.multipart?
          message.html_part&.body&.decoded
        elsif message.content_type&.include?('text/html')
          message.body.decoded
        end
      rescue StandardError => e
        Rails.logger.warn("MailerLog: Failed to extract HTML body: #{e.message}")
        nil
      end

      def extract_text_body(message)
        if message.multipart?
          message.text_part&.body&.decoded
        elsif message.content_type.nil? || message.content_type.include?('text/plain')
          message.body.decoded
        end
      rescue StandardError => e
        Rails.logger.warn("MailerLog: Failed to extract text body: #{e.message}")
        nil
      end

      def extract_headers(message)
        message.header.fields.each_with_object({}) do |field, hash|
          hash[field.name] = field.value
        end
      rescue StandardError => e
        Rails.logger.warn("MailerLog: Failed to extract headers: #{e.message}")
        {}
      end

      def capture_call_stack
        return nil unless MailerLog.configuration.capture_call_stack

        depth = MailerLog.configuration.call_stack_depth || 20
        caller.select { |line| line.include?(Rails.root.to_s) }
          .reject { |line| line.include?('mailer_log') }
          .first(depth)
      end
    end
  end
end

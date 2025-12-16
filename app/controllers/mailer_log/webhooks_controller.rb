# frozen_string_literal: true

module MailerLog
  class WebhooksController < ActionController::Base
    skip_before_action :verify_authenticity_token

    before_action :verify_signature
    before_action :handle_deduplicate_event

    # POST /mailer_log/webhooks/mailgun
    def mailgun
      event_data = params['event-data'] || params

      email = find_email(event_data)
      unless email
        Rails.logger.info("MailerLog: Email not found for webhook event")
        return head :ok
      end

      normalized_event = normalize_event_type(event_data['event'])
      create_event(email, event_data, normalized_event)
      email.update_status_from_event!(normalized_event)

      head :ok
    rescue StandardError => e
      Rails.logger.error("MailerLog webhook error: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      report_error(e)
      head :ok # Return 200 to prevent Mailgun retries for processing errors
    end

    private

    def verify_signature
      signature = params['signature']
      return head :unauthorized unless signature

      timestamp = signature['timestamp']
      token = signature['token']
      sig = signature['signature']

      return head :unauthorized unless timestamp && token && sig

      signing_key = MailerLog.configuration.webhook_signing_key
      return head :unauthorized unless signing_key

      expected = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new('SHA256'),
        signing_key,
        "#{timestamp}#{token}"
      )

      return if ActiveSupport::SecurityUtils.secure_compare(expected, sig)

      head :unauthorized
    end

    def handle_deduplicate_event
      event_id = params.dig('event-data', 'id')
      return true unless event_id

      cache_key = "mailer_log:event:#{event_id}"
      if Rails.cache.exist?(cache_key)
        head :ok
        return false
      end

      Rails.cache.write(cache_key, true, expires_in: 24.hours)
      true
    end

    def find_email(event_data)
      # Try message_id first
      message_id = event_data.dig('message', 'headers', 'message-id')
      if message_id.present?
        email = Email.find_by(message_id: message_id.gsub(/[<>]/, ''))
        return email if email
      end

      # Fallback to tracking_id from custom header
      tracking_id = event_data.dig('message', 'headers', 'x-mailer-log-tracking-id')
      Email.find_by(tracking_id: tracking_id) if tracking_id.present?
    end

    CLIENT_INFO_ATTRS = %w[user-agent device-type client-name client-os].freeze
    GEOLOCATION_ATTRS = %w[country region city].freeze
    DELIVERY_STATUS_ATTRS = %w[code message description mx-host attempt-no session-seconds utf8 tls certificate-verified].freeze

    def create_event(email, event_data, normalized_event)
      client_info = event_data['client-info'] || {}
      geolocation = event_data['geolocation'] || {}

      attrs = {
        event_type: normalized_event,
        mailgun_event_id: event_data['id'],
        occurred_at: extract_timestamp(event_data),
        recipient: event_data['recipient'],
        ip_address: event_data['ip'],
        url: event_data['url'],
        raw_payload: build_raw_payload(event_data, client_info, geolocation)
      }

      attrs.merge!(underscored_slice(client_info, CLIENT_INFO_ATTRS))
      attrs.merge!(underscored_slice(geolocation, GEOLOCATION_ATTRS))

      email.events.create!(attrs)
    end

    def underscored_slice(source, keys)
      return {} if source.blank?

      source.slice(*keys).transform_keys { |k| k.underscore.to_sym }
    end

    def build_raw_payload(event_data, client_info, geolocation)
      delivery_status = event_data['delivery-status']

      {
        event: event_data['event'],
        tags: event_data['tags'],
        campaigns: event_data['campaigns'],
        client_info: client_info.presence,
        geolocation: geolocation.presence,
        delivery_status: underscored_slice(delivery_status, DELIVERY_STATUS_ATTRS).presence,
        envelope: event_data['envelope'],
        message: event_data['message']&.slice('headers', 'size'),
        flags: event_data['flags'],
        severity: event_data['severity'],
        reason: event_data['reason'],
        log_level: event_data['log-level']
      }.compact_blank
    end

    def normalize_event_type(mailgun_event)
      case mailgun_event
      when 'permanent_fail' then 'bounced'
      when 'temporary_fail' then 'failed'
      else mailgun_event
      end
    end

    def extract_timestamp(event_data)
      timestamp = event_data['timestamp']
      Time.zone.at(timestamp.to_f) if timestamp.present?
    end

    def report_error(exception)
      Airbrake.notify(exception) if defined?(Airbrake)
    end
  end
end

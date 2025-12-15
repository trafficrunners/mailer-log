# frozen_string_literal: true

module MailerLog
  module Api
    class EmailsController < MailerLog::AdminController
      BASE_EMAIL_ATTRIBUTES = %i[
        id tracking_id message_id mailer_class mailer_action
        from_address to_addresses cc_addresses bcc_addresses
        subject domain status delivered_at opened_at clicked_at
        bounced_at created_at updated_at
      ].freeze
      BODY_ATTRIBUTES = %i[html_body text_body headers call_stack].freeze
      EVENT_ATTRIBUTES = %i[
        id event_type occurred_at recipient ip_address user_agent
        device_type client_name client_os country region city url raw_payload
      ].freeze

      skip_before_action :verify_authenticity_token, only: [:index, :show]

      def index
        emails = apply_filters(MailerLog::Email.order(created_at: :desc))
          .page(params[:page])
          .per(params[:per] || 25)

        render json: {
          emails: emails.map { |e| email_json(e) },
          total_count: emails.total_count,
          total_pages: emails.total_pages,
          current_page: emails.current_page
        }
      end

      def show
        email = MailerLog::Email.find(params[:id])

        render json: {
          email: email_json(email, include_body: true, include_events: true),
          config: {
            show_delivery_events: MailerLog.configuration.show_delivery_events?
          }
        }
      end

      private

      def apply_filters(scope)
        scope = scope.recipient(params[:recipient]) if params[:recipient].present?
        scope = scope.sender(params[:sender]) if params[:sender].present?
        scope = scope.subject_search(params[:subject_search]) if params[:subject_search].present?
        scope = scope.by_mailer(params[:mailer]) if params[:mailer].present?
        scope = scope.by_status(params[:status]) if params[:status].present?
        scope = scope.date_from(params[:date_from]) if params[:date_from].present?
        scope = scope.date_to(params[:date_to]) if params[:date_to].present?
        scope
      end

      def email_json(email, include_body: false, include_events: false)
        data = email.slice(*BASE_EMAIL_ATTRIBUTES)
        data.merge!(email.slice(*BODY_ATTRIBUTES)) if include_body
        data[:events] = email.events.recent.map { _1.slice(*EVENT_ATTRIBUTES) } if include_events
        data
      end
    end
  end
end

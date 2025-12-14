# frozen_string_literal: true

module MailerLog
  module Api
    class EmailsController < MailerLog::AdminController
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
          email: email_json(email, include_body: true, include_events: true)
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
        data = {
          id: email.id,
          tracking_id: email.tracking_id,
          message_id: email.message_id,
          mailer_class: email.mailer_class,
          mailer_action: email.mailer_action,
          from_address: email.from_address,
          to_addresses: email.to_addresses,
          cc_addresses: email.cc_addresses,
          bcc_addresses: email.bcc_addresses,
          subject: email.subject,
          domain: email.domain,
          status: email.status,
          delivered_at: email.delivered_at,
          opened_at: email.opened_at,
          clicked_at: email.clicked_at,
          bounced_at: email.bounced_at,
          created_at: email.created_at,
          updated_at: email.updated_at
        }

        if include_body
          data[:html_body] = email.html_body
          data[:text_body] = email.text_body
          data[:headers] = email.headers
          data[:call_stack] = email.call_stack
        end

        if include_events
          data[:events] = email.events.recent.map do |event|
            {
              id: event.id,
              event_type: event.event_type,
              occurred_at: event.occurred_at,
              recipient: event.recipient,
              ip_address: event.ip_address,
              user_agent: event.user_agent
            }
          end
        end

        data
      end
    end
  end
end

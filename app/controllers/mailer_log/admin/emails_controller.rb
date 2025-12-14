# frozen_string_literal: true

module MailerLog
  module Admin
    class EmailsController < ::AdminsController
      prepend HasScope

      # Expose main app routes to views
      helper Rails.application.routes.url_helpers

      has_scope :recipient
      has_scope :sender
      has_scope :subject_search
      has_scope :by_mailer, as: :mailer
      has_scope :by_status, as: :status
      has_scope :date_from
      has_scope :date_to

      def index
        @emails = apply_scopes(MailerLog::Email.order(created_at: :desc))
          .page(params[:page])
          .per(params[:per] || 25)
        @mailers = MailerLog::Email.distinct.pluck(:mailer_class).compact.sort
      end

      def show
        @email = MailerLog::Email.find(params[:id])
      end

      def preview
        @email = MailerLog::Email.find(params[:id])
        # rubocop:disable Rails/OutputSafety
        render html: @email.html_body&.html_safe, layout: false
        # rubocop:enable Rails/OutputSafety
      end

      private

      def mailer_log_engine
        MailerLog::Engine.routes.url_helpers
      end
      helper_method :mailer_log_engine
    end
  end
end

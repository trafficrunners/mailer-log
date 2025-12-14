# frozen_string_literal: true

module MailerLog
  class CleanupJob < ApplicationJob
    queue_as :default

    def perform
      retention_period = MailerLog.configuration.retention_period
      cutoff_date = retention_period.ago

      deleted_count = MailerLog::Email.where('created_at < ?', cutoff_date).delete_all

      Rails.logger.info("MailerLog::CleanupJob: Deleted #{deleted_count} emails older than #{cutoff_date}")
    end
  end
end

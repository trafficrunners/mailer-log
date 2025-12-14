# frozen_string_literal: true

module MailerLog
  class ApplicationJob < ActiveJob::Base
    # Retry on common transient failures
    retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
    retry_on ActiveRecord::LockWaitTimeout, wait: 5.seconds, attempts: 3

    # Discard job on unrecoverable errors
    discard_on ActiveJob::DeserializationError
  end
end

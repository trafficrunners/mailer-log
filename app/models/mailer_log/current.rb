# frozen_string_literal: true

module MailerLog
  # Thread-safe storage for passing data between interceptor and observer.
  # Uses ActiveSupport::CurrentAttributes which automatically resets
  # between requests and is safe for multi-threaded servers.
  class Current < ActiveSupport::CurrentAttributes
    attribute :email_data
  end
end

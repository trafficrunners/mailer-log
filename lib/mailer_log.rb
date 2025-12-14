# frozen_string_literal: true

require 'has_scope'
require 'kaminari'

require 'mailer_log/version'
require 'mailer_log/configuration'
require 'mailer_log/engine'

module MailerLog
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end

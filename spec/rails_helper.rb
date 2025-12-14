# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require_relative 'dummy/config/environment'

require 'rspec/rails'
require 'factory_bot_rails'

# Load support files
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include DeviseRequestHelpers, type: :request

  # Cranky compatibility - alias crank! to create
  config.include(Module.new do
    def crank!(factory, **attrs)
      create(factory, **attrs)
    end
  end)

end

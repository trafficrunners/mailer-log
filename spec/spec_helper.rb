# frozen_string_literal: true

# Load the main app's rails_helper to get full test environment
require_relative '../../../spec/rails_helper'

# Load engine factories into FactoryBot
Dir[MailerLog::Engine.root.join('spec/factories/**/*.rb')].each { |f| require f }

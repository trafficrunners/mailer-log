# frozen_string_literal: true

# Load the host app's rails_helper to get full test environment
# Adjust path as needed for your host app location
require_relative '../../gmbmanager/spec/rails_helper'

# Load engine factories into FactoryBot
Dir[MailerLog::Engine.root.join('spec/factories/**/*.rb')].each { |f| require f }

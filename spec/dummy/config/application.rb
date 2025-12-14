# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'

Bundler.require(*Rails.groups)
require 'mailer_log'

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    config.eager_load = false
    config.cache_classes = true

    # Set paths to use dummy app's config and app directories
    config.paths['config/database'] = [File.expand_path('database.yml', __dir__)]
    config.paths['config/routes.rb'] = [File.expand_path('routes.rb', __dir__)]
    config.paths['app/controllers'] = [File.expand_path('../app/controllers', __dir__)]
    config.paths['app/models'] = [File.expand_path('../app/models', __dir__)]

    # Autoload dummy app's controllers
    config.autoload_paths << File.expand_path('../app/controllers', __dir__)
    config.autoload_paths << File.expand_path('../app/models', __dir__)
  end
end

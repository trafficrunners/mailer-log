# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'mailer_log'
  s.version = '0.1.0'
  s.authors = ['TrafficRunners']
  s.email = ['team@localviking.com']
  s.summary = 'Rails engine for logging all outgoing emails with Mailgun webhook integration'
  s.description = 'Captures all outgoing emails, stores them in PostgreSQL, and tracks delivery events via Mailgun webhooks'
  s.license = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'README.md']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 3.4'

  s.add_dependency 'has_scope'
  s.add_dependency 'kaminari'
  s.add_dependency 'rails', '>= 7.0'

  s.add_development_dependency 'factory_bot_rails'
  s.add_development_dependency 'rspec-rails'
end

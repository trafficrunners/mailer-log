# frozen_string_literal: true

require_relative 'lib/mailer_log/version'

Gem::Specification.new do |s|
  s.name = 'mailer_log'
  s.version = MailerLog::VERSION
  s.authors = ['TrafficRunners']
  s.email = ['team@localviking.com']
  s.summary = 'Rails engine for logging outgoing emails with Mailgun webhook integration'
  s.description = 'A Rails engine that captures all outgoing emails, stores them in PostgreSQL, ' \
                  'provides a Vue.js admin UI for browsing emails, and tracks delivery events via Mailgun webhooks.'
  s.homepage = 'https://github.com/trafficrunners/mailer_log'
  s.license = 'MIT'

  s.metadata = {
    'homepage_uri' => s.homepage,
    'source_code_uri' => s.homepage,
    'changelog_uri' => "#{s.homepage}/blob/master/CHANGELOG.md",
    'rubygems_mfa_required' => 'true'
  }

  s.files = Dir.chdir(__dir__) do
    files = Dir['{app,config,db,lib,public}/**/*', 'README.md', 'LICENSE', 'CHANGELOG.md']
    # Include hidden .vite directory with manifest
    files += Dir['public/mailer_log/.vite/**/*']
    files
  end

  s.require_paths = ['lib']

  s.required_ruby_version = '>= 3.0'

  s.add_dependency 'has_scope', '~> 0.8'
  s.add_dependency 'kaminari', '~> 1.2'
  s.add_dependency 'rails', '>= 7.0', '< 9.0'
end

# frozen_string_literal: true

# Shim file to allow `gem 'mailer-log'` without `require: 'mailer_log'`
# Bundler auto-requires based on gem name, so this redirects to the actual file.
require_relative 'mailer_log'

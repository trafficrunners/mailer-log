# frozen_string_literal: true

module MailerLog
  module SpaHelper
    ASSET_PATH = '/mailer_log'

    def mailer_log_js_entry
      return nil if vite_dev_server_running?

      manifest = mailer_log_manifest
      return nil unless manifest

      entry = manifest['index.html'] || manifest['src/main.js']
      return nil unless entry

      file = entry.is_a?(Hash) ? entry['file'] : entry
      "#{ASSET_PATH}/#{file}"
    end

    def mailer_log_css_entry
      return nil if vite_dev_server_running?

      manifest = mailer_log_manifest
      return nil unless manifest

      entry = manifest['index.html']
      return nil unless entry.is_a?(Hash)

      css_file = entry['css']&.first
      return nil unless css_file

      "#{ASSET_PATH}/#{css_file}"
    end

    def mailer_log_dev_server_url
      return nil unless vite_dev_server_running?

      origin = defined?(ViteRuby) ? ViteRuby.config.origin : 'http://localhost:5173'
      "#{origin}#{ASSET_PATH}"
    end

    private

    def vite_dev_server_running?
      defined?(ViteRuby) && ViteRuby.instance.dev_server_running?
    end

    def mailer_log_manifest
      @mailer_log_manifest ||= begin
        # Check Rails app's public (after assets:precompile or copied)
        rails_manifest = Rails.root.join('public', 'mailer_log', '.vite', 'manifest.json')
        return JSON.parse(File.read(rails_manifest)) if File.exist?(rails_manifest)

        # Fallback to gem's built-in assets (served via middleware in dev)
        gem_manifest = MailerLog::Engine.root.join('public', 'mailer_log', '.vite', 'manifest.json')
        return JSON.parse(File.read(gem_manifest)) if File.exist?(gem_manifest)

        nil
      end
    end
  end
end

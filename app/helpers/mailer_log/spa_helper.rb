# frozen_string_literal: true

module MailerLog
  module SpaHelper
    def mailer_log_js_entry
      return nil if mailer_log_dev_server_url

      manifest = mailer_log_manifest
      return nil unless manifest

      entry = manifest['index.html'] || manifest['src/main.js']
      return nil unless entry

      file = entry.is_a?(Hash) ? entry['file'] : entry
      "#{asset_base_path}/#{file}"
    end

    def mailer_log_css_entry
      return nil if mailer_log_dev_server_url

      manifest = mailer_log_manifest
      return nil unless manifest

      entry = manifest['index.html']
      return nil unless entry.is_a?(Hash)

      css_file = entry['css']&.first
      return nil unless css_file

      "#{asset_base_path}/#{css_file}"
    end

    def mailer_log_dev_server_url
      return nil unless ENV['MAILER_LOG_DEV_SERVER_URL']

      "#{ENV['MAILER_LOG_DEV_SERVER_URL']}/mailer_log"
    end

    private

    def asset_base_path
      # In dev, middleware serves from gem's public dir at /mailer_log/
      # In production, assets are copied to asset pipeline dir
      if Rails.application.config.public_file_server.enabled
        '/mailer_log'
      else
        "/#{assets_dir}/mailer_log"
      end
    end

    def assets_dir
      @assets_dir ||= if defined?(ViteRuby)
        File.join(ViteRuby.config.public_output_dir, ViteRuby.config.assets_dir)
      elsif defined?(Webpacker)
        File.join(Webpacker.config.public_output_path.basename.to_s)
      else
        'assets'
      end
    end

    def mailer_log_manifest
      @mailer_log_manifest ||= begin
        # Check Rails app's asset output directory (after assets:precompile)
        rails_manifest = Rails.root.join('public', assets_dir, 'mailer_log', '.vite', 'manifest.json')
        return JSON.parse(File.read(rails_manifest)) if File.exist?(rails_manifest)

        # Fallback to gem's built-in assets (served via middleware in dev)
        gem_manifest = MailerLog::Engine.root.join('public', 'mailer_log', '.vite', 'manifest.json')
        return JSON.parse(File.read(gem_manifest)) if File.exist?(gem_manifest)

        nil
      end
    end
  end
end

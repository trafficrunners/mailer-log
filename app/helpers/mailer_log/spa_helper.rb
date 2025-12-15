# frozen_string_literal: true

module MailerLog
  module SpaHelper
    def mailer_log_asset_path(name)
      manifest = mailer_log_manifest
      base_path = request.script_name
      return "#{base_path}/assets/#{name}" unless manifest

      entry = manifest[name] || manifest["src/#{name}"] || manifest["assets/#{name}"]
      return "#{base_path}/assets/#{name}" unless entry

      file = entry.is_a?(Hash) ? entry['file'] : entry
      # Manifest paths already include 'assets/' prefix
      "#{base_path}/#{file}"
    end

    def mailer_log_js_entry
      manifest = mailer_log_manifest
      return nil unless manifest

      entry = manifest['index.html'] || manifest['src/main.js']
      return nil unless entry

      entry.is_a?(Hash) ? entry['file'] : entry
    end

    def mailer_log_css_entry
      manifest = mailer_log_manifest
      return nil unless manifest

      entry = manifest['index.html']
      return nil unless entry.is_a?(Hash)

      css_files = entry['css']
      css_files&.first
    end

    private

    def mailer_log_manifest
      @mailer_log_manifest ||= begin
        manifest_path = MailerLog::Engine.root.join('public', 'mailer_log', '.vite', 'manifest.json')
        return nil unless File.exist?(manifest_path)

        JSON.parse(File.read(manifest_path))
      end
    end
  end
end

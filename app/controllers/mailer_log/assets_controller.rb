# frozen_string_literal: true

module MailerLog
  class AssetsController < ActionController::Base
    skip_forgery_protection

    def show
      file_path = MailerLog::Engine.root.join('public', 'mailer_log', 'assets', params[:path])

      if File.exist?(file_path) && file_path.to_s.start_with?(MailerLog::Engine.root.join('public', 'mailer_log').to_s)
        content_type = content_type_for(file_path)
        send_file file_path, type: content_type, disposition: 'inline'
      else
        head :not_found
      end
    end

    private

    def content_type_for(file_path)
      extension = File.extname(file_path).downcase
      case extension
      when '.js'
        'application/javascript'
      when '.css'
        'text/css'
      when '.map'
        'application/json'
      when '.svg'
        'image/svg+xml'
      when '.png'
        'image/png'
      when '.jpg', '.jpeg'
        'image/jpeg'
      when '.woff', '.woff2'
        'font/woff2'
      else
        'application/octet-stream'
      end
    end
  end
end

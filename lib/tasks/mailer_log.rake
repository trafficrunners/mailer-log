# frozen_string_literal: true

namespace :mailer_log do
  desc 'Copy MailerLog assets to asset pipeline output directory'
  task install_assets: :environment do
    source = MailerLog::Engine.root.join('public', 'mailer_log')

    # Detect asset output directory from ViteRuby, Webpacker, or default to Sprockets
    assets_dir = if defined?(ViteRuby)
      File.join(ViteRuby.config.public_output_dir, ViteRuby.config.assets_dir)
    elsif defined?(Webpacker)
      File.join(Webpacker.config.public_output_path.basename.to_s)
    else
      'assets'
    end

    destination = Rails.root.join('public', assets_dir, 'mailer_log')

    unless source.exist?
      puts "ERROR: MailerLog assets not found at #{source}"
      exit 1
    end

    FileUtils.rm_rf(destination) if destination.exist?
    FileUtils.mkdir_p(destination.dirname)
    FileUtils.cp_r(source, destination)
    puts "MailerLog assets copied to #{destination}"
  end

  desc 'Create Mailgun webhooks for a domain. Usage: rake mailer_log:create_webhooks[example.com,https://app.example.com/admin/mailer-log/webhooks/mailgun]'
  task :create_webhooks, %i[domain webhook_url] => :environment do |_t, args|
    require 'net/http'
    require 'json'

    domain = args[:domain]
    webhook_url = args[:webhook_url]
    api_key = MailerLog.configuration.mailgun_api_key

    abort 'ERROR: domain is required. Usage: rake mailer_log:create_webhooks[example.com,https://...]' if domain.blank?
    abort 'ERROR: webhook_url is required. Usage: rake mailer_log:create_webhooks[example.com,https://...]' if webhook_url.blank?
    abort 'ERROR: MailerLog.configuration.mailgun_api_key is not set' if api_key.blank?

    # Mailgun webhook event types that map to MailerLog event types
    events = %w[delivered opened clicked permanent_fail temporary_fail complained unsubscribed]

    puts "Domain:      #{domain}"
    puts "Webhook URL: #{webhook_url}"
    puts "Events:      #{events.join(', ')}"
    puts

    # Fetch existing webhooks
    existing = mailgun_api_request(api_key, :get, "/v3/domains/#{domain}/webhooks")
    existing_events = existing&.dig('webhooks')&.keys || []
    puts "Existing webhooks: #{existing_events.any? ? existing_events.join(', ') : 'none'}"
    puts

    events.each do |event|
      if existing_events.include?(event)
        puts "  SKIP #{event} (already exists)"
        next
      end

      result = mailgun_api_request(api_key, :post, "/v3/domains/#{domain}/webhooks",
        id: event, url: webhook_url)

      if result&.dig('webhook', 'url') || result&.dig('message')&.include?('already')
        puts "  OK   #{event}"
      else
        puts "  FAIL #{event}: #{result}"
      end
    end

    puts "\nDone!"
  end
end

def mailgun_api_request(api_key, method, path, params = nil)
  uri = URI("https://api.mailgun.net#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = case method
  when :get
    Net::HTTP::Get.new(uri)
  when :post
    req = Net::HTTP::Post.new(uri)
    req.set_form_data(params) if params
    req
  end

  request.basic_auth('api', api_key)
  response = http.request(request)
  JSON.parse(response.body)
rescue JSON::ParserError
  { 'error' => "HTTP #{response.code}: #{response.body}" }
end

# Hook into assets:precompile
if Rake::Task.task_defined?('assets:precompile')
  Rake::Task['assets:precompile'].enhance do
    Rake::Task['mailer_log:install_assets'].invoke
  end
end

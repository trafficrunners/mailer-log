# frozen_string_literal: true

namespace :mailer_log do
  desc 'Copy MailerLog assets to asset pipeline output directory'
  task install_assets: :environment do
    source = MailerLog::Engine.root.join('public', 'mailer_log')

    # Detect asset output directory from ViteRuby or Webpacker
    output_dir = if defined?(ViteRuby)
      ViteRuby.config.public_output_dir
    elsif defined?(Webpacker)
      Webpacker.config.public_output_path.basename.to_s
    else
      'assets'
    end

    destination = Rails.root.join('public', output_dir, 'mailer_log')

    unless source.exist?
      puts "ERROR: MailerLog assets not found at #{source}"
      exit 1
    end

    FileUtils.rm_rf(destination) if destination.exist?
    FileUtils.mkdir_p(destination.dirname)
    FileUtils.cp_r(source, destination)
    puts "MailerLog assets copied to #{destination}"
  end
end

# Hook into assets:precompile
if Rake::Task.task_defined?('assets:precompile')
  Rake::Task['assets:precompile'].enhance do
    Rake::Task['mailer_log:install_assets'].invoke
  end
end

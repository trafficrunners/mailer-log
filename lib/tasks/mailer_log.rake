# frozen_string_literal: true

namespace :mailer_log do
  desc 'Copy MailerLog assets to public/'
  task install_assets: :environment do
    source = MailerLog::Engine.root.join('public', 'mailer_log')
    destination = Rails.root.join('public', 'mailer_log')

    unless source.exist?
      puts "ERROR: MailerLog assets not found at #{source}"
      exit 1
    end

    FileUtils.rm_rf(destination) if destination.exist?
    FileUtils.cp_r(source, destination)
    puts "MailerLog assets copied to #{destination}"
  end

  desc 'Build MailerLog Vue.js frontend (for gem development only)'
  task :build_frontend do
    frontend_dir = MailerLog::Engine.root.join('frontend')

    unless frontend_dir.exist?
      puts 'ERROR: Frontend source not available (only in gem source, not RubyGems)'
      exit 1
    end

    puts 'Installing npm dependencies...'
    system('npm install', chdir: frontend_dir.to_s) || raise('npm install failed')

    puts 'Building frontend...'
    system('npm run build', chdir: frontend_dir.to_s) || raise('npm build failed')

    puts 'Frontend built successfully!'
  end
end

# Hook into assets:precompile to copy MailerLog assets
if Rake::Task.task_defined?('assets:precompile')
  Rake::Task['assets:precompile'].enhance do
    Rake::Task['mailer_log:install_assets'].invoke
  end
end

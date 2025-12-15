# frozen_string_literal: true

namespace :mailer_log do
  desc 'Copy MailerLog assets to public/ (run after assets:precompile)'
  task :install_assets do
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

  desc 'Build MailerLog Vue.js frontend (set MAILER_LOG_OVERRIDES_PATH to customize components)'
  task :build_frontend do
    frontend_dir = MailerLog::Engine.root.join('frontend')

    unless frontend_dir.exist?
      puts <<~MSG
        ERROR: Frontend source not available.

        This task is for gem development only. When using mailer-log from RubyGems,
        the frontend is pre-built and included in public/mailer_log/.

        To customize the frontend with overrides:
        1. Clone the gem repository: git clone https://github.com/trafficrunners/mailer-log.git
        2. cd mailer-log/frontend
        3. MAILER_LOG_OVERRIDES_PATH=/path/to/your/overrides npm run build
        4. Copy public/mailer_log/ to your app
      MSG
      exit 1
    end

    overrides_path = ENV['MAILER_LOG_OVERRIDES_PATH']

    puts 'Installing npm dependencies...'
    system('npm install', chdir: frontend_dir.to_s) || raise('npm install failed')

    if overrides_path
      puts "Building frontend with overrides from: #{overrides_path}"
    else
      puts 'Building frontend (no overrides)...'
      puts 'Tip: Set MAILER_LOG_OVERRIDES_PATH to customize navbar and other components'
    end

    env = overrides_path ? { 'MAILER_LOG_OVERRIDES_PATH' => overrides_path } : {}
    system(env, 'npm run build', chdir: frontend_dir.to_s) || raise('npm build failed')

    puts 'Frontend built successfully!'
  end

  desc 'Build frontend with overrides and copy to host app public/'
  task build_and_install: :environment do
    frontend_dir = MailerLog::Engine.root.join('frontend')
    overrides_path = ENV['MAILER_LOG_OVERRIDES_PATH']

    if frontend_dir.exist? && overrides_path
      puts "Building MailerLog frontend with overrides..."
      Rake::Task['mailer_log:build_frontend'].invoke
    end

    Rake::Task['mailer_log:install_assets'].invoke
  end

  desc 'Start Vite development server for MailerLog frontend'
  task :dev_server do
    frontend_dir = MailerLog::Engine.root.join('frontend')

    unless frontend_dir.exist?
      puts <<~MSG
        ERROR: Frontend source not available.

        This task is for gem development only. When using mailer-log from RubyGems,
        the frontend is pre-built and served automatically.

        To develop the frontend with hot-reload:
        1. Clone the gem repository: git clone https://github.com/trafficrunners/mailer-log.git
        2. cd mailer-log/frontend
        3. npm install
        4. MAILER_LOG_OVERRIDES_PATH=/path/to/your/overrides npm run dev
      MSG
      exit 1
    end

    overrides_path = ENV['MAILER_LOG_OVERRIDES_PATH']

    puts 'Starting Vite dev server...'
    puts 'Frontend will be available at http://localhost:5173'
    puts 'Make sure Rails is running on http://localhost:3000'

    if overrides_path
      puts "Using overrides from: #{overrides_path}"
    end

    env = overrides_path ? { 'MAILER_LOG_OVERRIDES_PATH' => overrides_path } : {}
    exec(env, 'npm run dev', chdir: frontend_dir.to_s)
  end
end

# Hook into assets:precompile to automatically copy MailerLog assets
if Rake::Task.task_defined?('assets:precompile')
  Rake::Task['assets:precompile'].enhance do
    Rake::Task['mailer_log:install_assets'].invoke
  end
end

# frozen_string_literal: true

namespace :mailer_log do
  desc 'Build MailerLog Vue.js frontend (set MAILER_LOG_OVERRIDES_PATH to customize components)'
  task :build_frontend do
    frontend_dir = MailerLog::Engine.root.join('frontend')
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

  desc 'Start Vite development server for MailerLog frontend'
  task :dev_server do
    frontend_dir = MailerLog::Engine.root.join('frontend')
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

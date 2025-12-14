# frozen_string_literal: true

namespace :mailer_log do
  desc 'Build MailerLog Vue.js frontend'
  task :build_frontend do
    frontend_dir = MailerLog::Engine.root.join('frontend')

    puts 'Installing npm dependencies...'
    system('npm install', chdir: frontend_dir.to_s) || raise('npm install failed')

    puts 'Building frontend...'
    system('npm run build', chdir: frontend_dir.to_s) || raise('npm build failed')

    puts 'Frontend built successfully!'
  end

  desc 'Start Vite development server for MailerLog frontend'
  task :dev_server do
    frontend_dir = MailerLog::Engine.root.join('frontend')

    puts 'Starting Vite dev server...'
    puts 'Frontend will be available at http://localhost:5173'
    puts 'Make sure Rails is running on http://localhost:3000'
    exec('npm run dev', chdir: frontend_dir.to_s)
  end
end

# MailerLog

Rails engine for logging all outgoing emails with Mailgun webhook integration.

## Features

- Automatic capture of all outgoing emails (body, headers, mailer class/action)
- Call stack saving for debugging (shows where the email was triggered from)
- Mailgun webhook integration for delivery status tracking
- Modern Vue 3 + Tailwind CSS admin UI
- Email preview in sandboxed iframe
- Polymorphic association with Organization/Account for filtering by organization
- Configurable retention period with automatic cleanup

## Installation

### 1. Add to Gemfile

```ruby
# For local development (sibling directory)
gem 'mailer_log', path: '../mailer_log'

# For engines directory
# gem 'mailer_log', path: 'engines/mailer_log'
```

### 2. Run install generator

```bash
bundle install
rails generate mailer_log:install
rails db:migrate
```

This will:
- Create `config/initializers/mailer_log.rb` with configuration
- Copy migration to `db/migrate/`

### 3. Add routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount MailerLog::Engine, at: '/mailer_log'
end
```

### 4. Build the frontend (if needed)

The engine includes pre-built Vue.js frontend assets. If you need to rebuild:

```bash
# From host application
rake mailer_log:build_frontend

# Or directly
cd path/to/mailer_log/frontend
npm install
npm run build
```

### 5. Configure initializer

Edit `config/initializers/mailer_log.rb` to customize settings:

```ruby
MailerLog.configure do |config|
  # Email retention period (default 1 year)
  config.retention_period = 1.year

  # Key for Mailgun webhook verification
  config.webhook_signing_key = ENV['MAILGUN_WEBHOOK_SIGNING_KEY']

  # Capture call stack (useful for debugging)
  config.capture_call_stack = Rails.env.development?

  # Optional: Additional authentication for admin UI
  # config.authenticate_with do |controller|
  #   controller.send(:require_super_admin!)
  # end

  # Optional: Resolver for organization association
  # config.resolve_accountable do |email_record|
  #   User.find_by(email: email_record.to_addresses&.first)&.organization
  # end
end
```

## Mailgun Webhook Setup

### 1. Get Webhook Signing Key

1. Log in to [Mailgun Dashboard](https://app.mailgun.com/)
2. Go to **Sending** → **Webhooks**
3. Copy the **HTTP webhook signing key**
4. Add to ENV: `MAILGUN_WEBHOOK_SIGNING_KEY=your_key_here`

### 2. Configure Webhook URL

1. In Mailgun Dashboard, go to **Webhooks**
2. Add webhook for each event:
   - URL: `https://your-app.com/admin/email_log/webhooks/mailgun`
   - Events: `delivered`, `opened`, `clicked`, `bounced`, `failed`, `dropped`, `complained`

### 3. For Each Domain

If using multiple domains (white-label), configure webhooks for each.

## Usage

### Admin UI

After installation, accessible at: `/admin/email_log/admin/emails`

**Features:**
- List of all sent emails with pagination
- Filtering by: recipient, sender, subject, mailer class, status, date
- Email details view: headers, body preview, delivery events
- Call stack view (where in code the email was triggered)

### Email Statuses

| Status | Description |
|--------|-------------|
| `pending` | Email created, waiting to be sent |
| `sent` | Email sent to Mailgun |
| `delivered` | Email delivered to recipient |
| `opened` | Email opened (tracking pixel) |
| `clicked` | Link in email clicked |
| `bounced` | Email not delivered (hard bounce) |
| `complained` | Recipient marked as spam |

### Programmatic Access

```ruby
# Find all emails for a user
MailerLog::Email.recipient('user@example.com')

# Find emails by mailer class
MailerLog::Email.by_mailer('UsersMailer')

# Find undelivered emails
MailerLog::Email.by_status('bounced')

# Last 10 emails
MailerLog::Email.recent.limit(10)

# Emails with events
email = MailerLog::Email.find(id)
email.events.each do |event|
  puts "#{event.event_type} at #{event.occurred_at}"
end
```

### Cleaning Up Old Records

Add to Sidekiq cron or call periodically:

```ruby
# Run manually
MailerLog::CleanupJob.perform_now

# Via Sidekiq
MailerLog::CleanupJob.perform_later

# In sidekiq-cron (config/schedule.yml or sidekiq.yml)
cleanup_mailer_log:
  cron: '0 3 * * *'  # Daily at 3:00 AM
  class: MailerLog::CleanupJob
  queue: low_priority
```

## Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `retention_period` | `1.year` | Email retention period |
| `webhook_signing_key` | `nil` | Key for Mailgun webhook verification |
| `capture_call_stack` | `true` | Capture call stack |
| `call_stack_depth` | `20` | Call stack depth |
| `admin_layout` | `'application'` | Layout for admin views |
| `per_page` | `25` | Records per page |

## Troubleshooting

### Emails Not Being Saved

1. Check that engine is included in Gemfile and bundle install was run
2. Check that migrations are executed: `rails db:migrate:status`
3. Check logs for errors in `MailerLog::MailObserver`

### Webhooks Not Working

1. Check `MAILGUN_WEBHOOK_SIGNING_KEY` in ENV
2. Check that URL is accessible externally (not localhost)
3. Check logs for signature verification errors
4. In Mailgun Dashboard, check webhook status (failed/success)

### Events Not Linking to Emails

1. Check that `message_id` is being saved correctly
2. Check that header `X-Mailer-Log-Tracking-ID` is passed to Mailgun
3. Webhook may arrive before email is saved — retry mechanism is used

## Frontend Development

The admin UI is built with Vue 3 + Vite + Tailwind CSS.

### Development Mode

For hot-reload during development:

```bash
# Terminal 1: Start Rails server
rails server

# Terminal 2: Start Vite dev server
cd path/to/mailer_log/frontend
npm run dev
```

The Vue app will automatically use the Vite dev server at `http://localhost:5173` when assets are not built.

### Building for Production

```bash
rake mailer_log:build_frontend
```

Built assets are stored in `public/mailer_log/assets/`.

### Frontend Structure

```
frontend/
├── src/
│   ├── api/           # API client functions
│   ├── assets/        # CSS and static assets
│   ├── components/    # Reusable Vue components
│   ├── views/         # Page components
│   ├── App.vue        # Root component
│   └── main.js        # Entry point
├── index.html         # HTML template
├── package.json
├── tailwind.config.js
└── vite.config.js
```

## License

MIT

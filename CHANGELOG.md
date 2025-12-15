# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.5] - 2025-12-16

### Added

- Git revision capture for each email (from Capistrano REVISION file or `git rev-parse`)
- `github_repo` configuration option for linking call stack lines to GitHub source
- Clickable links in Call Stack tab that open source files on GitHub at the exact line

### Changed

- Improved Call Stack tab UI with card styling and parsed stack trace lines
- Mobile-responsive email detail panel and email list

## [0.1.6] - 2025-12-15

### Added

- Configurable `mount_path` option (default: `/admin/mailer-log`)
- `MailerLog.routes(self)` helper method for easier route mounting

## [0.1.5] - 2025-12-15

### Added

- Shim file `lib/mailer-log.rb` for auto-require (no more `require: 'mailer_log'` needed in Gemfile)

### Fixed

- Updated README with correct paths and documentation

## [0.1.4] - 2025-12-15

### Added

- Date range picker with presets (Today, This week, Last week, This month, Last month)
- Tooltips for long email addresses in detail panel

### Changed

- Improved email detail panel layout (From/To stacked vertically, mailer info aligned right)
- Close button moved to left side with back arrow icon

## [0.1.0] - 2024-12-14

### Added

- Initial release
- Rails engine for capturing all outgoing emails
- PostgreSQL storage for emails with full headers, body, and metadata
- Vue.js 3 admin UI with Tailwind CSS for browsing emails
- Mailgun webhook integration for delivery tracking (delivered, opened, clicked, bounced)
- Polymorphic `accountable` association for linking emails to business objects
- Configurable call stack capture for debugging
- JSON API for programmatic access
- Filter and search capabilities (by recipient, sender, subject, mailer, status, date range)
- Email preview with iframe rendering
- Delivery events timeline

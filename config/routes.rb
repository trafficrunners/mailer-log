# frozen_string_literal: true

MailerLog::Engine.routes.draw do
  # Webhook endpoint for email providers
  post 'webhooks/mailgun', to: 'webhooks#mailgun'

  # JSON API for Vue frontend
  namespace :api do
    resources :emails, only: %i[index show]
    resources :mailers, only: :index
  end

  # SPA catch-all - serves Vue app for all routes
  get '*path', to: 'spa#index'
  root to: 'spa#index'
end

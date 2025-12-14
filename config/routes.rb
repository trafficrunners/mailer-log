# frozen_string_literal: true

MailerLog::Engine.routes.draw do
  # Webhook endpoint for email providers
  post 'webhooks/mailgun', to: 'webhooks#mailgun'

  # JSON API for Vue frontend
  namespace :api do
    resources :emails, only: %i[index show]
    resources :mailers, only: :index
  end

  # Static assets for Vue SPA
  get 'assets/*path', to: 'assets#show', as: :asset, format: false

  # SPA catch-all - serves Vue app for all other routes
  get '/', to: 'spa#index'
  get '/*path', to: 'spa#index', constraints: ->(req) { !req.path.start_with?('/api', '/webhooks', '/assets') }
end

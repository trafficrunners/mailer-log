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

  # Legacy Admin UI (ERB-based) - keep for email preview iframe
  namespace :admin do
    resources :emails, only: %i[index show] do
      get :preview, on: :member
    end
  end

  # SPA catch-all - serves Vue app for all other routes
  get '/', to: 'spa#index'
  get '/*path', to: 'spa#index', constraints: ->(req) { !req.path.start_with?('/api', '/admin', '/webhooks', '/assets') }
end

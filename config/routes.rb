# frozen_string_literal: true

MailerLog::Engine.routes.draw do
  # Webhook endpoint for email providers
  post 'webhooks/mailgun', to: 'webhooks#mailgun'

  # Admin UI
  namespace :admin do
    resources :emails, only: %i[index show] do
      get :preview, on: :member
    end
  end

  # Root path redirects to admin emails
  root to: 'admin/emails#index'
end

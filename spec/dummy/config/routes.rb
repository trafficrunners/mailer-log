# frozen_string_literal: true

Rails.application.routes.draw do
  mount MailerLog::Engine, at: '/admin/email_log'
end

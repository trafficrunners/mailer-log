# frozen_string_literal: true

# Mock Devise helpers for testing without the full Devise gem
module DeviseTestHelpers
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :user_signed_in? if respond_to?(:helper_method)
  end

  def current_user
    Thread.current[:test_current_user]
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    return if current_user

    redirect_to '/', alert: 'You need to sign in first'
  end
end

# Mixin for request specs
module DeviseRequestHelpers
  def sign_in(user)
    Thread.current[:test_current_user] = user
  end

  def sign_out(_user = nil)
    Thread.current[:test_current_user] = nil
  end
end

# frozen_string_literal: true

# Mock AdminsController that provides base functionality for engine's AdminController
class AdminsController < ApplicationController
  include DeviseTestHelpers

  before_action :authenticate_user!
  before_action :require_admin!

  private

  def require_admin!
    return if current_user&.admin?

    redirect_to '/', alert: 'Access denied'
  end
end

# frozen_string_literal: true

class User < ApplicationRecord
  belongs_to :organization, optional: true

  def admin?
    email == 'team@localviking.com'
  end
end

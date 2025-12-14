# frozen_string_literal: true

module MailerLog
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end

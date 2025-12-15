# frozen_string_literal: true

module MailerLog
  class Configuration
    attr_accessor :retention_period,
      :webhook_signing_key,
      :capture_call_stack,
      :call_stack_depth,
      :per_page,
      :header_partial,
      :show_delivery_events

    attr_reader :authenticate_with_proc, :resolve_accountable_proc

    def initialize
      @retention_period = 1.year
      @webhook_signing_key = nil
      @capture_call_stack = true
      @call_stack_depth = 20
      @per_page = 25
      @header_partial = nil # e.g., 'shared/admin_navbar'
      @show_delivery_events = nil # nil = auto (true if webhook_signing_key present)
      @authenticate_with_proc = nil
      @resolve_accountable_proc = nil
    end

    def authenticate_with(&block)
      @authenticate_with_proc = block
    end

    def resolve_accountable(&block)
      @resolve_accountable_proc = block
    end

    def show_delivery_events?
      return @show_delivery_events unless @show_delivery_events.nil?

      @webhook_signing_key.present?
    end
  end
end

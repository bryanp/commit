# frozen_string_literal: true

require "yaml"

require_relative "event"

module Commit
  # Operations perform one or more actions on a scope.
  #
  class Operation
    attr_reader :scope, :event

    def initialize(scope:, event:)
      @scope = scope
      @event = event
    end

    def call(*args, **kwargs)
      # implemented by subclasses
    end

    class << self
      def call(*args, scope:, event:, **kwargs)
        instance = new(scope: scope, event: event)
        instance.call(*args, **kwargs)
        instance
      end
    end
  end
end

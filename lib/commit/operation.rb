# frozen_string_literal: true

require "yaml"

module Commit
  # Operations perform one or more actions on a scope.
  #
  class Operation
    attr_reader :scope

    def initialize(scope:)
      @scope = scope
    end

    def call(*args, **kwargs)
      # implemented by subclasses
    end

    class << self
      def call(*args, scope:, **kwargs)
        instance = new(scope: scope)
        instance.call(*args, **kwargs)
        instance
      end
    end
  end
end

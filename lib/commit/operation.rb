# frozen_string_literal: true

require "forwardable"
require "yaml"

require_relative "event"

module Commit
  # Operations perform one or more actions on a scope.
  #
  class Operation
    attr_reader :scope, :event, :artifacts

    extend Forwardable
    def_delegators :"@scope", :config, :data

    def initialize(scope:, event:)
      @scope = scope
      @event = event
      @artifacts = []
    end

    def call(*args, **kwargs)
      # implemented by subclasses
    end

    # @api private
    private def cleanup
      @artifacts.each do |path|
        FileUtils.rm_r(path)
      end
    end

    class << self
      def call(*args, scope:, event:, **kwargs)
        instance = new(scope: scope, event: event)
        instance.call(*args, **kwargs)
        yield instance if block_given?
        instance
      ensure
        instance.send(:cleanup)
      end
    end
  end
end

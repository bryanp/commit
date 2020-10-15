# frozen_string_literal: true

require "pathname"
require "yaml"

require_relative "config"

module Commit
  class Event
    class << self
      def global(envar = "GITHUB_EVENT_PATH")
        @_global ||= new(config: Config.load(ENV[envar]))
      end

      def reset
        remove_instance_variable(:@_global) if defined?(@_global)
      end
    end

    attr_reader :config

    def initialize(config:)
      @config = config
    end
  end
end

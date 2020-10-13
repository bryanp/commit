# frozen_string_literal: true

require "pathname"
require "yaml"

require_relative "config"

module Commit
  class Event
    class << self
      def global(envar = "GITHUB_EVENT_PATH")
        @_global ||= new(config: Config.new(load_config(Pathname.new(ENV[envar].to_s))))
      end

      # @api private
      private def load_config(config_path)
        if config_path.exist?
          YAML.safe_load(config_path.read)
        else
          {}
        end
      end
    end

    attr_reader :config

    def initialize(config:)
      @config = config
    end
  end
end

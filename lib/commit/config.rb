# frozen_string_literal: true

module Commit
  class Config
    # @api private
    attr_reader :settings

    def initialize(settings)
      @settings = settings
    end

    def method_missing(name)
      name = name.to_s

      if name.end_with?("!")
        @settings&.dig(name[0..-2])
      else
        wrap(@settings&.dig(name))
      end
    end

    def respond_to_missing?(*)
      true
    end

    def ==(other)
      case other
      when Config
        other.settings == @settings
      when Hash
        other == @settings
      else
        false
      end
    end

    # @api private
    private def wrap(value)
      case value
      when Hash, NilClass
        self.class.new(value)
      when Array
        value.map { |each_value|
          wrap(each_value)
        }
      else
        value
      end
    end
  end
end

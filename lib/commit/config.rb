# frozen_string_literal: true

module Commit
  class Config
    class StringBuilder
      PATTERN = /{([^}]*)}/

      def initialize(string)
        @string = string
      end

      def build(context)
        working = @string.dup

        working.scan(PATTERN).each do |match|
          value = resolve_value(match[0], context)

          working.gsub!("{#{match[0]}}", value)
        end

        working
      end

      # @api private
      private def resolve_value(name, context)
        value = nil

        name.split(".").each do |name_part|
          value = context.public_send(name_part.to_sym)

          context = value
        end

        value
      end
    end

    class << self
      def load(path)
        path = Pathname.new(path.to_s)

        settings = if path.exist?
          YAML.safe_load(path.read)
        else
          {}
        end

        new(settings)
      end
    end

    # @api private
    attr_reader :settings

    def initialize(settings)
      @settings = settings
    end

    def expand(setting, context:)
      value = @settings[setting.to_s]

      if value.is_a?(String)
        StringBuilder.new(value).build(context)
      else
        value
      end
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

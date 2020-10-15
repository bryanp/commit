# frozen_string_literal: true

require "delegate"

module Commit
  class Data
    attr_reader :path

    def initialize(path)
      @path = Pathname.new(path)
    end

    def method_missing(name, *args, **kwargs)
      data_path = @path.join("#{name}.yml")

      if data_path.exist?
        Wrapper.load(data_path)
      else
        super
      end
    end

    def respond_to_missing?(name, *)
      @path.join("#{name}.yml").exist? || super
    end
  end

  class Wrapper
    class << self
      def load(path)
        path = Pathname.new(path.to_s)

        new(YAML.safe_load(path.read))
      end
    end

    attr_reader :value

    def initialize(value)
      @value = value
    end

    def method_missing(name, *args, **kwargs)
      if @value.respond_to?(name)
        if block_given?
          ret = @value.public_send(name, *args, **kwargs) { |value|
            yield self.class.new(value)
          }

          self.class.new(ret)
        else
          self.class.new(@value.public_send(name, *args, **kwargs))
        end
      elsif @value.is_a?(Hash) && @value.include?(name.to_s)
        self.class.new(@value[name.to_s])
      else
        super
      end
    end

    def respond_to_missing?(name, *)
      @value.respond_to?(name) || (@value.is_a?(Hash) && @value.include?(name.to_s)) || super
    end

    def to_s
      @value.to_s
    end
  end
end

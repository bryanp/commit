# frozen_string_literal: true

require "erb"
require "fileutils"

module Commit
  class Template
    def initialize(path)
      @path = path

      @erb = ERB.new(File.read(path), trim_mode: "%-")
    end

    def generate(at:, context:)
      unless File.exist?(File.dirname(at))
        FileUtils.mkdir_p(File.dirname(at))
      end

      File.open(at, "w+") { |file|
        file.write(render(context))
      }
    end

    def render(context, **locals)
      context_binding = context.instance_eval {
        binding
      }

      @erb.result(context_binding)
    end
  end
end

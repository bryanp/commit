# frozen_string_literal: true

require "pathname"
require "yaml"

require_relative "config"
require_relative "data"

module Commit
  # Scopes represent a configured context to run tools in.
  #
  class Scope
    class << self
      def each(root = Dir.pwd, &block)
        return enum_for(:each, root) unless block_given?

        root = Pathname.new(root)
        root.glob("**/*", File::FNM_DOTMATCH).select { |path|
          path.basename.fnmatch?(COMMIT_TOOLS_DIRECTORY)
        }.reject { |path|
          # Ignore commit directories within hidden folders.
          #
          path.dirname.to_s.split("/").any? { |part| part[0] == "." }
        }.reject { |path|
          # Ignore commit directories within tmp folders.
          #
          path.dirname.to_s.split("/").any? { |part| part == "tmp" }
        }.map { |path|
          new(path: path)
        }.each(&block)
      end
    end

    attr_reader :path, :config, :data

    def initialize(path:)
      @path = Pathname.new(path)
      @config = Config.load(@path.join(CONFIG_FILE))
      @data = Data.new(@path.join(DATA_PATH))
    end

    # @api private
    COMMIT_TOOLS_DIRECTORY = ".commit"
    # @api private
    CONFIG_FILE = "config.yml"
    # @api private
    DATA_PATH = "data"
  end
end

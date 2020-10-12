# frozen_string_literal: true

require "forwardable"

require_relative "../../operation"
require_relative "../../template"

require_relative "../git/commit"
require_relative "../git/push"

module Commit
  module Operations
    module Templates
      # Updates templates in context of the current scope.
      #
      class Update < Operation
        extend Forwardable
        def_delegators :"@scope", :config

        def call
          generate_templates
          commit_and_push
        end

        # @api private
        private def generate_templates
          templates_path = @scope.path.join(TEMPLATES_DIRECTORY)

          each_template_config do |template_config|
            template = Template.new(templates_path.join(template_config["template"]))

            generated_path = resolve_generated_path(template_config)
            template.generate(at: generated_path, context: self)
          end
        end

        # @api private
        private def commit_and_push
          Commit::Operations::Git::Commit.call(scope: scope, event: event, message: "update templates")

          Commit::Operations::Git::Push.call(scope: scope, event: event)
        end

        # @api private
        private def each_template_config
          return enum_for(:each_template_config) unless block_given?

          config["templates"].to_a.each do |template_config|
            yield template_config
          end
        end

        # @api private
        private def resolve_generated_path(template_config)
          template_path = template_config["path"]
          template = template_config["template"]

          case template_path
          when NilClass
            File.basename(template, File.extname(template))
          else
            if File.extname(template_path).empty?
              File.join(template_path, File.basename(template, File.extname(template)))
            else
              template_path
            end
          end
        end

        # @api private
        TEMPLATES_DIRECTORY = "templates"
      end
    end
  end
end
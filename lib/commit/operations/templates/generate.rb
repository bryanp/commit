# frozen_string_literal: true

require_relative "../../operation"
require_relative "../../template"

module Commit
  module Operations
    module Templates
      class Generate < Operation
        def call
          templates_path = @scope.path.join(TEMPLATES_DIRECTORY)

          each_template_config do |template_config|
            template = Template.new(templates_path.join(template_config.template))

            generated_path = resolve_generated_path(template_config)
            template.generate(at: generated_path, context: self)
          end
        end

        # @api private
        private def each_template_config
          return enum_for(:each_template_config) unless block_given?

          config.commit.templates.to_a.each do |template_config|
            yield template_config
          end
        end

        # @api private
        private def resolve_generated_path(template_config)
          template_path = template_config.expand(:path, context: self)
          template = template_config.template

          case template_path
          when NilClass
            File.basename(template, File.extname(template))
          else
            template_path
          end
        end

        # @api private
        TEMPLATES_DIRECTORY = "templates"
      end
    end
  end
end

# frozen_string_literal: true

require_relative "../../operation"
require_relative "../../template"

module Commit
  module Operations
    module Templates
      class Generate < Operation
        def call
          each_template_config do |template_config|
            template = Template.new(templates_path.join(template_config.expand(:source, context: self)))

            generated_path = @scope.path.join("../", resolve_generated_path(template_config))
            template.generate(at: generated_path, context: self)
          end
        end

        def render(path, **locals)
          template = Template.new(templates_path.join(path))
          template.render(self, **locals)
        end

        private def templates_path
          @scope.path.join(TEMPLATES_DIRECTORY)
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
          template_path = template_config.expand(:destination, context: self)
          template = template_config.source

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

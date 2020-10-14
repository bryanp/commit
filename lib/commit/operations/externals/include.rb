# frozen_string_literal: true

require "pakyow/support/deep_dup"

require_relative "../../operation"

module Commit
  module Operations
    module Externals
      class Include < Operation
        using Pakyow::Support::DeepDup

        attr_reader :result

        def call
          configured_templates = config.templates!

          if configured_templates.nil?
            config.settings["templates"] = []
            configured_templates = config.templates!
          end

          each_applicable_group_template do |template, external_config|
            # TODO: Decide if mutating state that's passed in is desirable or if a better pattern is needed.
            #
            configured_templates << {
              "source" => @scope.path.join(
                TEMPLATES_DIRECTORY, external_config.repo, template.source
              ).to_s,

              "destination" => template.destination
            }
          end
        end

        # @api private
        private def applicable_group?(group)
          config.commit.includes.to_a.include?(group.name)
        end

        # @api private
        private def applicable_template?(template)
          !config.commit.templates.to_a.any? { |configured_template|
            File.expand_path(configured_template.destination) == File.expand_path(template.destination)
          }
        end

        # @api private
        private def each_applicable_group_template
          each_applicable_group.sort { |(a, _), (b, _)|
            config.commit.includes.index(a.name) <=> config.commit.includes.index(b.name)
          }.each do |group, external_config|
            group.templates.each do |template|
              yield template, external_config if applicable_template?(template)
            end
          end
        end

        # @api private
        private def each_applicable_group
          return enum_for(:each_applicable_group) unless block_given?

          each_external_config do |external_config|
            external_config.commit.groups.to_a.each do |group|
              yield group, external_config if applicable_group?(group)
            end
          end
        end

        # @api private
        private def each_external_config
          return enum_for(:each_external_config) unless block_given?

          config.commit.externals.to_a.each do |external_config|
            config = Config.load(@scope.path.join(TEMPLATES_DIRECTORY, external_config.repo, ".commit/config.yml"))

            # TODO: This feels incorrect, but we need it above.
            #
            config.settings["repo"] = external_config.repo

            yield config
          end
        end

        # @api private
        TEMPLATES_DIRECTORY = "templates"
      end
    end
  end
end

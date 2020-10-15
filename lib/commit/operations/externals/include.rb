# frozen_string_literal: true

require "deep_merge"
require "pakyow/support/deep_dup"

require_relative "../../operation"

module Commit
  module Operations
    module Externals
      class Include < Operation
        using Pakyow::Support::DeepDup

        attr_reader :result

        def call
          include_config
          include_templates
        end

        # @api private
        private def include_config
          each_sorted_applicable_group do |group|
            next unless group.config.settings

            group.config.settings.each_pair do |key, value|
              if config.settings.include?(key)
                case value
                when Array
                  settings = config.settings[key]

                  value.each do |each_value|
                    settings << each_value unless settings.include?(each_value)
                  end
                when Hash
                  config.settings[key].deep_merge!(value)
                end
              else
                config.settings[key] = value
              end
            end
          end
        end

        # @api private
        private def include_templates
          configured_templates = config.commit.templates!

          if configured_templates.nil?
            configured_templates = []

            config.commit.settings["templates"] = configured_templates
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
          each_sorted_applicable_group.each do |group, external_config|
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
        private def each_sorted_applicable_group
          return enum_for(:each_sorted_applicable_group) unless block_given?

          each_applicable_group.sort { |(a, _), (b, _)|
            config.commit.includes.index(a.name) <=> config.commit.includes.index(b.name)
          }.each do |group, external_config|
            yield group, external_config
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

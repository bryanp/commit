# frozen_string_literal: true

require_relative "../../operation"

module Commit
  module Operations
    module Changelogs
      class Include < Operation
        def call
          return unless data.respond_to?(:releases)

          configured_templates = config.commit.ensure(:templates, [])
          default_changelog = File.expand_path("../templates/changelog.md.erb", __FILE__)

          each_changelog_config do |changelog_config|
            configured_templates << {
              "source" => changelog_config.source! || default_changelog,
              "destination" => changelog_config.destination!
            }
          end
        end

        # @api private
        private def each_changelog_config
          return enum_for(:each_changelog_config) unless block_given?

          config.commit.changelogs.to_a.each do |changelog_config|
            yield changelog_config
          end
        end
      end
    end
  end
end

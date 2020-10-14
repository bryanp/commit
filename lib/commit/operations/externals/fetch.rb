# frozen_string_literal: true

require_relative "../../operation"

require_relative "../git/clone"

module Commit
  module Operations
    module Externals
      class Fetch < Operation
        def call
          externals_path = @scope.path.join(TEMPLATES_DIRECTORY)

          each_external_config do |external_config|
            external_path = externals_path.join(external_config.repo)
            artifacts << external_path

            Git::Clone.call(
              scope: scope,
              event: event,
              repo: external_config.repo,
              auth: external_config.private,
              path: external_path
            )
          end
        end

        # @api private
        private def each_external_config
          return enum_for(:each_external_config) unless block_given?

          config.externals.to_a.each do |external_config|
            yield external_config
          end
        end

        # @api private
        TEMPLATES_DIRECTORY = "templates"
      end
    end
  end
end

# frozen_string_literal: true

require_relative "../../operation"
require_relative "../github/dispatch"

module Commit
  module Operations
    module Dependents
      class Update < Operation
        def call(user: ENV["COMMIT__GIT_USER"], token: ENV["COMMIT__GIT_TOKEN"])
          each_dependent_config do |dependent_config|
            Commit::Operations::Github::Dispatch.call(scope: scope, event: event, repo: dependent_config["repo"])
          end
        end

        # @api private
        private def each_dependent_config
          return enum_for(:each_dependent_config) unless block_given?

          config["dependents"].to_a.each do |dependent_config|
            yield dependent_config
          end
        end
      end
    end
  end
end

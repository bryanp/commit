# frozen_string_literal: true

require_relative "../../operation"

require_relative "../changelogs/include"

require_relative "../externals/fetch"
require_relative "../externals/include"

require_relative "../git/commit"
require_relative "../git/pull"
require_relative "../git/push"

require_relative "generate"

module Commit
  module Operations
    module Templates
      # Updates templates in context of the current scope.
      #
      class Update < Operation
        def call
          # return unless applicable?

          Git::Pull.call(scope: scope, event: event)

          Externals::Fetch.call(scope: scope, event: event) do
            Changelogs::Include.call(scope: scope, event: event)
            Externals::Include.call(scope: scope, event: event)
            Templates::Generate.call(scope: scope, event: event)
          end

          Git::Commit.call(scope: scope, event: event, message: "update templates")
          Git::Push.call(scope: scope, event: event)
        end

        private def applicable?
          default_branch?
        end

        private def default_branch?
          committed_to_default? || merged_to_default?
        end

        private def committed_to_default?
          event.config.ref!.to_s.split("/").last == event.config.repository.default_branch!
        end

        private def merged_to_default?
          merged? && event.config.pull_request.base.ref! == event.config.pull_request.base.repo.default_branch!
        end

        private def merged?
          event.config.pull_request.merged!
        end
      end
    end
  end
end

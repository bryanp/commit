# frozen_string_literal: true

require_relative "../externals/fetch"

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
          Git::Pull.call(scope: scope, event: event)

          Externals::Fetch.call(scope: scope, event: event) do
            Templates::Generate.call(scope: scope, event: event)
          end

          Git::Commit.call(scope: scope, event: event, message: "update templates")
          Git::Push.call(scope: scope, event: event)
        end
      end
    end
  end
end

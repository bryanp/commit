# frozen_string_literal: true

require_relative "../../operation"

module Commit
  module Operations
    module Git
      class Push < Operation
        def call(user: ENV["COMMIT__GIT_USER"], token: ENV["COMMIT__GIT_TOKEN"], repo: @event.config.dig("repository", "name"))
          `git pull --rebase`

          `git push https://#{user}:#{token}@github.com/#{repo}.git`
        end
      end
    end
  end
end

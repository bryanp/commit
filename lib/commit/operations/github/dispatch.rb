# frozen_string_literal: true

require_relative "../../operation"

module Commit
  module Operations
    module Github
      class Dispatch < Operation
        def call(repo:, user: ENV["COMMIT__GIT_USER"], token: ENV["COMMIT__GIT_TOKEN"])
          command = <<~COMMAND
            curl \
              -v \
              -u #{user}:#{token} \
              -X POST \
              -H "Accept: application/vnd.github.v3+json" \
              https://api.github.com/repos/#{repo}/dispatches \
              -d '{"event_type":"commit.touch"}'
          COMMAND

          `#{command}`
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "../../operation"

module Commit
  module Operations
    module Github
      class Dispatch < Operation
        def call(repo:, token: ENV["COMMIT__GIT_TOKEN"])
          command = <<~COMMAND
            curl \
              -v \
              -X POST \
              -H "Authorization: token #{token}" \
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

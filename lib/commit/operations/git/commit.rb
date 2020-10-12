# frozen_string_literal: true

require_relative "../../operation"

module Commit
  module Operations
    module Git
      class Commit < Operation
        def call(message:)
          `git pull --rebase`

          `git add -A`

          `git commit -a -m "[commit] #{escape(message)}" || echo "nothing to commit"`
        end

        private def escape(string)
          string.dump[1..-2]
        end
      end
    end
  end
end

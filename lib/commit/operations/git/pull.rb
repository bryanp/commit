# frozen_string_literal: true

require_relative "../../operation"

module Commit
  module Operations
    module Git
      class Pull < Operation
        def call
          `git pull --rebase`
        end
      end
    end
  end
end

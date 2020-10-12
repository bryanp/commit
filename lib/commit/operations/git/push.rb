# frozen_string_literal: true

require_relative "../../operation"

module Commit
  module Operations
    module Git
      class Push < Operation
        def call
          `git push`
        end
      end
    end
  end
end

# frozen_string_literal: true

require "fileutils"

require_relative "../../operation"

module Commit
  module Operations
    module Git
      class Clone < Operation
        def call(repo:, path:, auth: false, user: ENV["COMMIT__GIT_USER"], token: ENV["COMMIT__GIT_TOKEN"])
          FileUtils.mkdir_p(path)

          if auth
            puts "cloning private repo as `#{user}'..."
            `git clone https://#{user}:#{token}@github.com/#{repo}.git #{path}`
          else
            puts "cloning public repo..."
            `git clone git@github.com:#{repo} #{path}`
          end
        end
      end
    end
  end
end

require "octokit"

client = Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])
pp client.pull_request(ENV["GITHUB_REPOSITORY"], ENV["GITHUB_PULL_REQUEST"])

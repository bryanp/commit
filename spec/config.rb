ENV["GITHUB_WORKFLOW_PATH"] = File.expand_path("../support/workflows", __FILE__)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    # TODO This option will default to `true` in RSpec 4. Remove then.
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # TODO Will default to `true` in RSpec 4. Remove then
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.warnings = true
  config.color = true

  config.order = :random
  Kernel.srand config.seed

  config.before do
    require "commit/operations/git/commit"
    require "commit/operations/git/push"

    allow(Commit::Operations::Git::Commit).to receive(:call)
    allow(Commit::Operations::Git::Push).to receive(:call)
  end

  config.before do
    @original_env = ENV.clone
    ENV["COMMIT__DRYRUN"] = "true"
    ENV["COMMIT__GIT_EMAIL"] = "commit@metabahn.com"
    ENV["COMMIT__GIT_NAME"] = "Commit Test"
  end

  config.after do
    %w[GIT_EMAIL GIT_NAME].each do |name|
      if @original_env.include?(name)
        ENV[name] = @original_env[name]
      else
        ENV.delete(name)
      end
    end
  end
end

RSpec::Matchers.define :eq_sans_whitespace do |expected|
  match do |actual|
    expected.gsub(/\s+/, "") == actual.gsub(/\s+/, "")
  end

  diffable
end

RSpec::Matchers.define :include_sans_whitespace do |expected|
  match do |actual|
    actual.to_s.gsub(/\s+/, "").include?(expected.to_s.gsub(/\s+/, ""))
  end

  diffable
end

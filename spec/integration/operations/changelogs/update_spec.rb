# frozen_string_literal: true

require "fileutils"

RSpec.describe "update changelogs operation" do
  let(:bin_path) {
    Pathname.new(File.expand_path("../../../../../bin", __FILE__))
  }

  let(:github_event_path) {
    support_path.join(".github/event.yml")
  }

  let(:support_path) {
    Pathname.new(File.expand_path("../update/support/simple", __FILE__))
  }

  let(:artifacts) {
    [
      support_path.join(".commit/data")
    ]
  }

  let(:releases_path) {
    support_path.join(".commit/data/releases.yml")
  }

  def perform
    Dir.chdir(support_path) do
      load(bin_path.join("update-changelogs"))
    end
  end

  before do
    ENV["GITHUB_EVENT_PATH"] = github_event_path.to_s
  end

  after do
    artifacts.each do |path|
      if path.file?
        FileUtils.rm(path)
      elsif path.directory?
        FileUtils.rm_r(path)
      end
    end

    ENV.delete("GITHUB_EVENT_PATH")
  end

  it "creates a new release data file with expected changes" do
    perform

    expect(YAML.safe_load(releases_path.read)).to eq(
      [{"version" => "v1.0.0",
        "changes" =>
         [{"id" => 4,
           "type" => "add",
           "summary" => "Update README.md",
           "link" => "https://github.com/metabahn/commit-tools-test/pull/4",
           "author" => {"username" => "bryanp", "link" => "https://github.com/bryanp"}}]}]
    )
  end

  describe "adding a change to an existing release" do
    let(:support_path) {
      Pathname.new(File.expand_path("../update/support/existing-release", __FILE__))
    }

    let(:artifacts) { [] }

    before do
      @original_releases_data = releases_path.read
    end

    after do
      releases_path.open("w+") do |file|
        file.write(@original_releases_data)
      end
    end

    it "adds the new change at the top of the existing release" do
      perform

      expect(YAML.safe_load(releases_path.read)).to eq(
        [{"version" => "v2.0.0",
          "changes" =>
           [{"id" => "3",
             "type" => "fix",
             "summary" => "this is another v2.0 change",
             "link" => "https://github.com/metabahn/commit-test/pull/3",
             "author" => {"link" => "https://github.com/bryanp", "username" => "bryanp"}}]},
          {"version" => "v1.0.0",
           "date" => "2020-10-15",
           "link" => "https://github.com/metabahn/commit-test/releases/tag/v1.0.0",
           "changes" =>
            [{"id" => 4,
              "type" => "add",
              "summary" => "Update README.md",
              "link" => "https://github.com/metabahn/commit-tools-test/pull/4",
              "author" => {"username" => "bryanp", "link" => "https://github.com/bryanp"}},
              {"id" => "1",
               "type" => "add",
               "summary" => "this is a v1.0 change",
               "link" => "https://github.com/metabahn/commit-test/pull/1",
               "author" => {"link" => "https://github.com/bryanp", "username" => "bryanp"}}]}]
      )
    end
  end

  describe "adding a new release to existing release data" do
    let(:support_path) {
      Pathname.new(File.expand_path("../update/support/existing-data", __FILE__))
    }

    let(:artifacts) { [] }

    before do
      @original_releases_data = releases_path.read
    end

    after do
      releases_path.open("w+") do |file|
        file.write(@original_releases_data)
      end
    end

    it "adds the new release at the appropriate location" do
      perform

      expect(YAML.safe_load(releases_path.read)).to eq(
        [{"version" => "v2.0.0",
          "changes" =>
           [{"id" => "3",
             "type" => "fix",
             "summary" => "this is another v2.0 change",
             "link" => "https://github.com/metabahn/commit-test/pull/3",
             "author" => {"link" => "https://github.com/bryanp", "username" => "bryanp"}}]},
          {"version" => "v1.0.0",
           "changes" =>
            [{"id" => 4,
              "type" => "add",
              "summary" => "Update README.md",
              "link" => "https://github.com/metabahn/commit-tools-test/pull/4",
              "author" => {"username" => "bryanp", "link" => "https://github.com/bryanp"}}]}]
      )
    end
  end

  context "event is not a merged pull request" do
    let(:support_path) {
      Pathname.new(File.expand_path("../update/support/unmerged", __FILE__))
    }

    it "ignores the event" do
      perform

      expect(releases_path.exist?).to be(false)
    end
  end

  context "pull request is not tagged with a known changelog label" do
    let(:support_path) {
      Pathname.new(File.expand_path("../update/support/unknown-changelog-label", __FILE__))
    }

    it "ignores the event" do
      perform

      expect(releases_path.exist?).to be(false)
    end
  end

  context "pull request is not tagged with a known changetype" do
    let(:support_path) {
      Pathname.new(File.expand_path("../update/support/unknown-changetype-label", __FILE__))
    }

    it "ignores the event" do
      perform

      expect(releases_path.exist?).to be(false)
    end
  end

  context "pull request is not assigned to a milestone" do
    let(:support_path) {
      Pathname.new(File.expand_path("../update/support/unknown-milestone", __FILE__))
    }

    it "ignores the event" do
      perform

      expect(releases_path.exist?).to be(false)
    end
  end
end

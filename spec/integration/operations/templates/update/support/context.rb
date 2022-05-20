# frozen_string_literal: true

require "fileutils"

require "commit/operations/templates/update"

RSpec.shared_context "operations: update" do
  let(:bin_path) {
    Pathname.new(File.expand_path("../../../../../../../bin", __FILE__))
  }

  let(:github_event_path) {
    support_path.join(".github/event.yml")
  }

  def generate
    Dir.chdir(support_path) do
      load(bin_path.join("update-templates"))
    end
  end

  before do
    allow(Commit::Operations::Git::Clone).to receive(:call)

    ENV["GITHUB_EVENT_PATH"] = github_event_path.to_s
  end

  after do
    generated.each do |path|
      if path.file?
        FileUtils.rm(path)
      elsif path.directory?
        FileUtils.rm_r(path)
      end
    end

    ENV.delete("GITHUB_EVENT_PATH")
  end
end

# frozen_string_literal: true

require "fileutils"

require "commit/operations/git/clone"

RSpec.describe "update templates operation" do
  let(:bin_path) {
    Pathname.new(File.expand_path("../../../../../bin", __FILE__))
  }

  let(:support_path) {
    Pathname.new(File.expand_path("../update/support/simple", __FILE__))
  }

  let(:generated) {
    [
      support_path.join("my-gem.gemspec")
    ]
  }

  def generate
    Dir.chdir(support_path) do
      load(bin_path.join("update-templates"))
    end
  end

  before do
    allow(Commit::Operations::Git::Clone).to receive(:call)
  end

  after do
    generated.each do |path|
      if path.file?
        FileUtils.rm(path)
      elsif path.directory?
        FileUtils.rm_r(path)
      end
    end
  end

  describe "fetching external templates" do
    let(:support_path) {
      Pathname.new(File.expand_path("../update/support/externals", __FILE__))
    }

    let(:generated) { [] }

    it "clones external templates" do
      expect(Commit::Operations::Git::Clone).to receive(:call) do |**kwargs|
        expect(kwargs[:repo]).to eq("metabahn/commit-templates")
        expect(kwargs[:auth]).to eq(true)
        expect(kwargs[:path].to_s.end_with?("support/externals/.commit/templates/metabahn/commit-templates")).to be(true)

        FileUtils.mkdir_p(kwargs[:path])
      end

      generate
    end
  end

  describe "generating files from templates" do
    it "creates each defined template" do
      generate

      expect(support_path.join("my-gem.gemspec").exist?).to be(true)
    end

    it "builds each template in context of the operation" do
      generate

      # The template wouldn't have access to config if it's compiled in the wrong context.
      #
      expect(support_path.join("my-gem.gemspec").read).to include_sans_whitespace(
        <<~CONTENT
          spec.name = "my-gem"
        CONTENT
      )
    end

    context "template is configured with a nested path" do
      let(:support_path) {
        Pathname.new(File.expand_path("../update/support/nested", __FILE__))
      }

      let(:generated) {
        [
          support_path.join("foo")
        ]
      }

      it "generates a file named after the template" do
        generate

        expect(support_path.join("foo/bar/itsa.gemspec").exist?).to be(true)
      end
    end

    context "template is configured without a path" do
      let(:support_path) {
        Pathname.new(File.expand_path("../update/support/pathless", __FILE__))
      }

      let(:generated) {
        [
          support_path.join("my-gem.gemspec")
        ]
      }

      it "generates at the root scope" do
        generate

        expect(support_path.join("my-gem.gemspec").exist?).to be(true)
      end
    end

    context "template does not exist" do
      let(:support_path) {
        Pathname.new(File.expand_path("../update/support/missing", __FILE__))
      }

      it "raises an error" do
        expect {
          generate
        }.to raise_error(Errno::ENOENT) do |error|
          expect(error.message).to include("No such file or directory")
          expect(error.message).to include("update/support/missing/.commit/templates/my-gem.gemspec.erb")
        end
      end
    end

    context "template fails to compile" do
      let(:support_path) {
        Pathname.new(File.expand_path("../update/support/failed", __FILE__))
      }

      it "raises an error" do
        expect {
          generate
        }.to raise_error(NameError)
      end
    end
  end

  describe "cleaning up external repos" do
    let(:support_path) {
      Pathname.new(File.expand_path("../update/support/externals", __FILE__))
    }

    let(:generated) { [] }

    it "removes external repos" do
      external_path = nil

      expect(Commit::Operations::Git::Clone).to receive(:call) do |**kwargs|
        external_path = kwargs[:path]

        FileUtils.mkdir_p(kwargs[:path])
      end

      generate

      expect(external_path.exist?).to be(false)
    end
  end

  describe "committing and pushing the changes" do
    it "invokes the commit and push operation" do
      expect(Commit::Operations::Git::Commit).to receive(:call) do |**kwargs|
        expect(kwargs[:message]).to eq("update templates")
      end

      expect(Commit::Operations::Git::Push).to receive(:call)

      generate
    end
  end
end

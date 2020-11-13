# frozen_string_literal: true

require "fileutils"

require "commit/operations/git/clone"

RSpec.describe "update templates operation" do
  let(:bin_path) {
    Pathname.new(File.expand_path("../../../../../bin", __FILE__))
  }

  let(:github_event_path) {
    support_path.join(".github/event.yml")
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

    context "template expands the path" do
      let(:support_path) {
        Pathname.new(File.expand_path("../update/support/expanded", __FILE__))
      }

      let(:generated) {
        [
          support_path.join("test-expand.gemspec")
        ]
      }

      it "expands the template path" do
        generate

        expect(support_path.join("test-expand.gemspec").exist?).to be(true)
      end
    end
  end

  describe "including templates from external groups" do
    let(:support_path) {
      Pathname.new(File.expand_path("../update/support/group-templates", __FILE__))
    }

    let(:generated) { [] }

    # Mock the externals since they'll be cleaned up as artifacts.
    #
    before do
      test_templates_1_path = support_path.join(".commit/templates/metabahn/test-templates-1")
      FileUtils.mkdir_p(test_templates_1_path.join(".commit"))
      generated << support_path.join(".commit/templates/metabahn")

      test_templates_1_path.join(".commit/config.yml").open("w+") do |file|
        file.write <<~CONTENT
          commit:
            groups:
              - name: "foo"
                templates:
                  - source: "foo.erb"
                    destination: "./foo"
                  - source: "foobaz.erb"
                    destination: "./baz"

              - name: "bar"
                templates:
                  - source: "bar.erb"
                    destination: "./bar"

              - name: "baz"
                templates:
                  - source: "baz.erb"
                    destination: "./baz"

              - name: "qux"
                templates:
                  - source: "qux.erb"
                    destination: "./qux"
        CONTENT
      end

      test_templates_1_path.join("foo.erb").open("w+") do |file|
        file.write <<~CONTENT
          test-templates-1-foo
          <%= config.project.name %>
        CONTENT
      end

      test_templates_1_path.join("bar.erb").open("w+") do |file|
        file.write <<~CONTENT
          test-templates-1-bar
        CONTENT
      end

      test_templates_1_path.join("foobaz.erb").open("w+") do |file|
        file.write <<~CONTENT
          test-templates-1-foobaz
        CONTENT
      end

      test_templates_1_path.join("baz.erb").open("w+") do |file|
        file.write <<~CONTENT
          test-templates-1-baz
        CONTENT
      end

      test_templates_1_path.join("qux.erb").open("w+") do |file|
        file.write <<~CONTENT
          test-templates-1-qux
        CONTENT
      end
    end

    it "includes templates for included groups" do
      generate

      expect(support_path.join("foo").read).to eq_sans_whitespace(
        <<~CONTENT
          test-templates-1-foo
          test!
        CONTENT
      )
    end

    it "does not include templates for groups that have not been included" do
      generate

      expect(support_path.join("bar").exist?).to be(false)
    end

    context "multiple included groups define the same template" do
      it "includes the template with the highest priority" do
        generate

        expect(support_path.join("baz").read).to eq_sans_whitespace(
          <<~CONTENT
            test-templates-1-baz
          CONTENT
        )
      end
    end

    context "template is already defined by the including repo" do
      it "does not include the template from the external group" do
        generate

        expect(support_path.join("qux").read).to eq_sans_whitespace(
          <<~CONTENT
            qux
          CONTENT
        )
      end
    end
  end

  describe "including config from external groups" do
    let(:support_path) {
      Pathname.new(File.expand_path("../update/support/group-config", __FILE__))
    }

    let(:generated) { [] }

    # Mock the externals since they'll be cleaned up as artifacts.
    #
    before do
      test_templates_1_path = support_path.join(".commit/templates/metabahn/test-templates-1")
      FileUtils.mkdir_p(test_templates_1_path.join(".commit"))
      generated << support_path.join(".commit/templates/metabahn")

      test_templates_1_path.join(".commit/config.yml").open("w+") do |file|
        file.write <<~CONTENT
          commit:
            groups:
              - name: "foo"
                config:
                  shared: true
                  override: true

              - name: "bar"
                config:
                  ignore:
                    - bar

              - name: "baz"
                config:
                  hashed:
                    baz: baz

              - name: "qux"
                config:
                  deeply:
                    nested:
                      setting: true
                  ignore:
                    - qux
        CONTENT
      end
    end

    it "includes shared settings" do
      generate

      expect(support_path.join("inspect").read).to include_sans_whitespace(
        <<~CONTENT
          shared: true
        CONTENT
      )
    end

    it "does not override existing settings" do
      generate

      expect(support_path.join("inspect").read).to include_sans_whitespace(
        <<~CONTENT
          override: false
        CONTENT
      )
    end

    it "merges array settings" do
      generate

      expect(support_path.join("inspect").read).to include_sans_whitespace(
        <<~CONTENT
          ignore: ["project", "qux", "bar"]
        CONTENT
      )
    end

    it "merges hash settings" do
      generate

      expect(support_path.join("inspect").read).to include_sans_whitespace(
        <<~CONTENT
          hashed: {"project"=>true, "nested"=>{"works"=>true}, "baz"=>"baz"}
        CONTENT
      )
    end

    it "merges deeply nested settings" do
      generate

      expect(support_path.join("inspect").read).to include_sans_whitespace(
        <<~CONTENT
          deeply: {"nested"=>{"setting"=>true}}
        CONTENT
      )
    end
  end

  describe "including changelogs" do
    let(:support_path) {
      Pathname.new(File.expand_path("../update/support/changelogs", __FILE__))
    }

    let(:generated) {
      [
        support_path.join("CHANGELOG.md"),
        support_path.join("nested/CHANGELOG.md")
      ]
    }

    it "generates top-level changelogs" do
      generate

      expect(support_path.join("CHANGELOG.md").read).to eq_sans_whitespace(
        <<~CONTENT
          ## v2.0.0

          *unreleased*

            * `fix` [#3](https://github.com/metabahn/commit-test/pull/3) this is another v2.0 change ([bryanp](https://github.com/bryanp))
            * `chg` [#2](https://github.com/metabahn/commit-test/pull/2) this is a v2.0 change ([bryanp](https://github.com/bryanp))

          ## [v1.0.0](https://github.com/metabahn/commit-test/releases/tag/v1.0.0)

          *released on 2020-10-15*

            * `add` [#1](https://github.com/metabahn/commit-test/pull/1) this is a v1.0 change ([bryanp](https://github.com/bryanp))
        CONTENT
      )
    end

    it "generates nested changelogs" do
      generate

      expect(support_path.join("nested/CHANGELOG.md").read).to eq_sans_whitespace(
        <<~CONTENT
          nested changelog
        CONTENT
      )
    end

    it "does not generates changelogs for scopes with no release data" do
      generate

      expect(support_path.join("no-data/CHANGELOG.md").exist?).to be(false)
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

  context "event is not for the default branch" do
    let(:support_path) {
      Pathname.new(File.expand_path("../update/support/non-default", __FILE__))
    }

    let(:generated) {
      [
        support_path.join("CHANGELOG.md")
      ]
    }

    it "ignores the event" do
      generate

      expect(support_path.join("CHANGELOG.md").exist?).to be(false)
    end
  end
end

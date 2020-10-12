# frozen_string_literal: true

require "commit/scope"

RSpec.describe Commit::Scope do
  let(:support_path) {
    Pathname.new(File.expand_path("../scope/support", __FILE__))
  }

  describe "::new" do
    subject {
      described_class.new(path: support_path)
    }

    it "initializes with a path" do
      expect(subject).to be_instance_of(described_class)
    end

    describe "initializing with a string path" do
      subject {
        described_class.new(path: support_path.to_s)
      }

      it "converts the path to a pathname" do
        expect(subject.path).to eq(support_path)
      end
    end
  end

  describe "::each" do
    it "finds scopes at pwd by default" do
      Dir.chdir(support_path.join("each")) do
        scopes = described_class.each.to_a

        expect(scopes.count).to eq(2)
        expect(scopes[0].path.fnmatch?("*/support/each/.commit")).to be(true)
        expect(scopes[1].path.fnmatch?("*/support/each/nested/.commit")).to be(true)
      end
    end

    context "passing a path" do
      it "finds scopes at the given path" do
        scopes = described_class.each(support_path.join("each/nested")).to_a

        expect(scopes.count).to eq(1)
        expect(scopes[0].path.fnmatch?("*/support/each/nested/.commit")).to be(true)
      end
    end
  end

  describe "#config" do
    context "scope has a config file" do
      subject {
        described_class.new(path: support_path.join("config/.commit")).config
      }

      it "returns the config" do
        expect(subject).to eq("configured" => true)
      end
    end

    context "scope does not have a config file" do
      subject {
        described_class.new(path: support_path.join("config/unconfigured/.commit")).config
      }

      it "returns an empty hash" do
        expect(subject).to eq({})
      end
    end
  end
end

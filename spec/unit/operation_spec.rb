# frozen_string_literal: true

require "commit/operation"
require "commit/scope"

RSpec.describe Commit::Operation do
  let(:scope) {
    Commit::Scope.new(path: Dir.pwd)
  }

  describe "::call" do
    before do
      allow(described_class).to receive(:new).with(scope: scope).and_return(instance)
      allow(instance).to receive(:call)
    end

    let(:instance) {
      instance_double(described_class)
    }

    subject {
      described_class.call(scope: scope)
    }

    it "calls the instance with args and kwargs" do
      described_class.call(:foo, scope: scope, bar: :baz)

      expect(instance).to have_received(:call).with(:foo, bar: :baz)
    end

    it "returns an instance" do
      expect(subject).to be(instance)
    end
  end

  describe "#scope" do
    subject {
      described_class.new(scope: scope)
    }

    it "returns the scope" do
      expect(subject.scope).to be(scope)
    end
  end
end

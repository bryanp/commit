# frozen_string_literal: true

require "commit/operations/templates/update"

RSpec.describe "bin/update-templates" do
  let(:bin_path) {
    Pathname.new(File.expand_path("../../../../bin", __FILE__))
  }

  let(:support_path) {
    Pathname.new(File.expand_path("../update-templates/support", __FILE__))
  }

  it "invokes the update templates operation on each scope" do
    expect(Commit::Operations::Templates::Update).to receive(:call) do |scope:|
      expect(scope.config).to eq("name" => "one")
    end

    expect(Commit::Operations::Templates::Update).to receive(:call) do |scope:|
      expect(scope.config).to eq("name" => "two")
    end

    Dir.chdir(support_path) do
      load(bin_path.join("update-templates"))
    end
  end
end

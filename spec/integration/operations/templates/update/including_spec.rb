# frozen_string_literal: true

require_relative "support/context"

RSpec.describe "including templates" do
  let(:support_path) {
    Pathname.new(File.expand_path("../support/includes", __FILE__))
  }

  let(:generated) {
    [
      support_path.join("my-file.txt")
    ]
  }

  include_context "operations: update"

  it "can include templates, exposing local values" do
    generate

    expect(support_path.join("my-file.txt").read).to include_sans_whitespace(
        <<~CONTENT
          head
          included(bar)
          foot
        CONTENT
      )
  end
end

# frozen_string_literal: true

require "spec_helper"

describe OmniAuth::Strategies::Civicrm do
  subject { described_class.new(nil, {}) }

  let(:extra) { { contact: { display_name: "John+Doe" } } }
  let(:raw_info) { { "preferred_username" => "john.doe" } }

  before do
    allow_any_instance_of(described_class).to receive(:extra).and_return(extra)
    allow_any_instance_of(described_class).to receive(:raw_info).and_return(raw_info)
  end

  context "when the name is invalid" do
    it "is sanitized" do
      expect(subject.parsed_name).to eq("JohnDoe")
    end
  end

  context "when the nickname is invalid" do
    it "is sanitized" do
      expect(subject.parsed_nickname).to eq("john_doe")
    end
  end
end

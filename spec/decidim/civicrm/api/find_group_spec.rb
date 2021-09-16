# frozen_string_literal: true

require "spec_helper"

describe Decidim::Civicrm::Api::FindGroup, type: :class do
  subject { described_class.new(1) }

  describe "#result" do
    before do
      stub_api_request(:find_group)
    end

    it "returns a Hash with the result" do
      expect(subject.result).to be_a Hash
    end
  end
end

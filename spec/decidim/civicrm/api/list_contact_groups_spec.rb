# frozen_string_literal: true

require "spec_helper"

describe Decidim::Civicrm::Api::ListContactGroups, type: :class do
  subject { described_class.new(1) }

  describe "#result" do
    before do
      stub_api_request(:list_contact_groups)
    end

    let(:result) { subject.result }

    it "returns an Array with the result" do
      expect(result).to be_a Array
      expect(result).to eq [1]
    end
  end
end

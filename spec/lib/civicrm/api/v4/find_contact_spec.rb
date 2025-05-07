# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim
  describe Civicrm::Api::Find, type: :class do
    subject { described_class.new("contact", 42) }

    include_context "with stubs example api v4"

    let(:data) { JSON.parse(file_fixture("v4/find_contact_valid_response.json").read) }

    describe "#result" do
      it "returns a mapped object" do
        expect(subject.result).to be_a Hash
        expect(subject.result[:contact]).to be_a Hash
        expect(subject.result[:memberships]).to be_a Array
        expect(subject.result[:contact]).to be_a Hash
        expect(subject.result[:contact][:id]).to eq(data["values"].first["id"].to_i)
        expect(subject.result[:contact][:display_name]).to eq(data["values"].first["display_name"])
        expect(subject.result[:memberships]).to match_array(data["values"].pluck("membership.membership_type_id"))
      end
    end
  end
end

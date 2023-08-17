# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim
  describe Civicrm::Api::FindUser, type: :class do
    subject { described_class.new(42) }

    include_context "with stubs example api"

    let(:data) { JSON.parse(file_fixture("find_user_valid_response.json").read) }

    describe "#result" do
      it "returns a mapped object" do
        expect(subject.result).to be_a Hash
        expect(subject.result[:user]).to be_a Hash
        expect(subject.result[:memberships]).to be_a Array
        expect(subject.result[:contact]).to be_a Hash
        expect(subject.result[:user][:id]).to eq(data["values"].first["id"].to_i)
        expect(subject.result[:user][:name]).to eq(data["values"].first["name"])
        expect(subject.result[:user][:email]).to eq(data["values"].first["email"])
        expect(subject.result[:user][:contact_id]).to eq(data["values"].first["contact_id"].to_i)
        expect(subject.result[:memberships]).to eq(data["values"].first["api.Membership.get"]["values"].map { |v| v["membership_type_id"].to_i })
        expect(subject.result[:contact][:id]).to eq(data["values"].first["contact_id"].to_i)
        expect(subject.result[:contact][:display_name]).to eq(data["values"].first["api.Contact.get"]["values"].first["display_name"])
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim
  describe Civicrm::Api::ListMembershipTypes, type: :class do
    subject { described_class.new }

    include_context "with stubs example api"

    let(:data) { JSON.parse(file_fixture("list_membership_types_valid_response.json").read) }

    describe "#result" do
      it "returns array of objects" do
        expect(subject.result).to be_a Array
        data["values"].each do |group|
          group = {
            id: group["id"].to_i,
            name: group["name"]
          }
          expect(subject.result).to include(group)
        end
      end
    end
  end
end

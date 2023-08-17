# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim
  describe Civicrm::Api::ListContactsInGroup, type: :class do
    subject { described_class.new(1) }

    include_context "with stubs example api"

    let(:data) { JSON.parse(file_fixture("list_contacts_in_group_valid_response.json").read) }

    describe "#result" do
      it "returns array of objects" do
        expect(subject.result).to be_a Array
        data["values"].each do |member|
          member = {
            contact_id: member["contact_id"].to_i,
            display_name: member["display_name"]
          }
          expect(subject.result).to include(member)
        end
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim
  describe Civicrm::Api::List, type: :class do
    subject { described_class.new("group_contacts", 1) }

    include_context "with stubs example api v4"

    let(:data) { JSON.parse(file_fixture("v4/list_group_contacts_valid_response.json").read) }

    describe "#result" do
      it "returns array of objects" do
        expect(subject.result).to be_a Array
        data["values"].each do |member|
          member = {
            contact_id: member["id"].to_i,
            display_name: member["display_name"]
          }
          expect(subject.result).to include(member)
        end
      end
    end
  end
end

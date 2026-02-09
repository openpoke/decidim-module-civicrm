# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim
  module Civicrm
    module Api
      module V4
        describe ListGroupContacts, type: :class do
          include_context "with stubs example api v4"

          subject { described_class.new(group_id) }

          let(:group_id) { 100 }
          let(:data) { JSON.parse(file_fixture("v4/list_group_contacts_valid_response.json").read) }

          describe "#result" do
            it "returns array of contacts" do
              expect(subject.result).to be_a Array
              expect(subject.result.length).to eq(3)
            end

            it "parses contacts correctly" do
              result = subject.result

              expect(result).to include({ contact_id: 17, display_name: "User 1" })
              expect(result).to include({ contact_id: 18, display_name: "User 2" })
              expect(result).to include({ contact_id: 23, display_name: "User 3" })
            end

            context "when group has no members" do
              let(:data) { JSON.parse(file_fixture("v4/empty_response.json").read) }

              it "returns empty array" do
                expect(subject.result).to eq([])
              end
            end
          end

          describe ".parse_item" do
            it "extracts contact_id and display_name" do
              item = { "id" => 42, "display_name" => "Test User" }
              result = described_class.parse_item(item)

              expect(result[:contact_id]).to eq(42)
              expect(result[:display_name]).to eq("Test User")
            end
          end
        end
      end
    end
  end
end

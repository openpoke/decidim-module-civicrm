# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim
  module Civicrm
    module Api
      module V4
        describe ListGroupContacts, type: :class do
          include_context "with stubs example api v4"

          subject { described_class.new(group_id, fetch_all: true) }

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

          describe "#count" do
            it "returns the total count from API" do
              expect(subject.count).to eq(3)
            end

            context "when fetch_all is false" do
              subject { described_class.new(group_id, fetch_all: false) }

              it "returns the total count even when only fetching first page" do
                expect(subject.count).to eq(3)
              end
            end
          end

          describe "with page parameter" do
            let(:page_size) { 1 }
            let(:first_page_data) do
              {
                "values" => [
                  { "id" => 17, "display_name" => "User 1" }
                ],
                "entity" => "Contact",
                "action" => "get",
                "count" => 3,
                "countFetched" => 1,
                "countMatched" => 3
              }
            end
            let(:api_returns) do
              [
                {
                  status: 200,
                  body: first_page_data.to_json,
                  headers: {}
                }
              ]
            end

            before do
              allow(Decidim::Civicrm).to receive(:api_records_by_page).and_return(page_size)
            end

            subject { described_class.new(group_id, fetch_all: false, page: 0) }

            it "fetches only the specified page" do
              expect(subject.result.length).to eq(1)
              expect(subject.result).to contain_exactly({ contact_id: 17, display_name: "User 1" })
            end

            it "returns correct total count" do
              expect(subject.count).to eq(3)
            end

            context "with page 1" do
              let(:second_page_data) do
                {
                  "values" => [
                    { "id" => 18, "display_name" => "User 2" }
                  ],
                  "entity" => "Contact",
                  "action" => "get",
                  "count" => 3,
                  "countFetched" => 1,
                  "countMatched" => 3
                }
              end
              let(:api_returns) do
                [
                  {
                    status: 200,
                    body: second_page_data.to_json,
                    headers: {}
                  }
                ]
              end

              subject { described_class.new(group_id, fetch_all: false, page: 1) }

              it "fetches the second page" do
                expect(subject.result.length).to eq(1)
                expect(subject.result).to contain_exactly({ contact_id: 18, display_name: "User 2" })
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

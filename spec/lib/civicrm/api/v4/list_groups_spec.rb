# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim
  describe Civicrm::Api::List, type: :class do
    subject { described_class.new("groups") }

    include_context "with stubs example api v4"

    let(:data) { JSON.parse(file_fixture("v4/list_groups_valid_response.json").read) }

    describe "#result" do
      it "returns array of objects" do
        expect(subject.result).to be_a Array
        data["values"].each do |group|
          group = {
            id: group["id"].to_i,
            name: group["name"],
            title: group["title"],
            description: group["description"],
            group_type: group["group_type"].map(&:to_i)
          }
          expect(subject.result).to include(group:)
        end
      end
    end

    describe "#count" do
      it "returns the total count from API" do
        expect(subject.count).to eq(2)
      end
    end

    describe "with pagination" do
      let(:page_size) { 1 }
      let(:first_page_data) do
        {
          "values" => [data["values"].first],
          "entity" => "Group",
          "action" => "get",
          "count" => 2,
          "countFetched" => 1,
          "countMatched" => 2
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

      subject { described_class.new("groups", fetch_all: false, page: 0) }

      it "fetches only the specified page" do
        expect(subject.result.length).to eq(1)
      end

      it "returns correct total count" do
        expect(subject.count).to eq(2)
      end
    end
  end
end

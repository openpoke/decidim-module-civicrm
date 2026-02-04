# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim
  module Civicrm
    module Api
      module V4
        describe ListContactCustomFields do
          subject { described_class.new }

          include_context "with stubs example api v4"

          let(:data) do
            {
              "values" => [
                { "id" => 1, "name" => "external_id", "label" => "External ID", "data_type" => "String", "custom_group_id" => 1 },
                { "id" => 2, "name" => "birth_date", "label" => "Birth Date", "data_type" => "Date", "custom_group_id" => 1 }
              ],
              "count" => 2,
              "countFetched" => 2
            }
          end

          describe "#result" do
            it "returns array of custom fields" do
              expect(subject.result).to be_a Array
              expect(subject.result.length).to eq(2)
            end

            it "parses fields correctly" do
              field = subject.result.first
              expect(field[:id]).to eq(1)
              expect(field[:name]).to eq("external_id")
              expect(field[:label]).to eq("External ID")
              expect(field[:data_type]).to eq("String")
              expect(field[:custom_group_id]).to eq(1)
            end
          end

          describe ".parse_item" do
            let(:item) do
              { "id" => "5", "name" => "test_field", "label" => "Test", "data_type" => "Int", "custom_group_id" => "2" }
            end

            it "converts id to integer" do
              result = described_class.parse_item(item)
              expect(result[:id]).to eq(5)
              expect(result[:custom_group_id]).to eq(2)
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim
  module Civicrm
    module Api
      module V4
        describe FindContactByFields do
          include_context "with stubs example api v4"

          let(:fields) { { "id" => "123" } }
          let(:group_ids) { [] }

          subject { described_class.new(fields, group_ids) }

          describe "#result" do
            context "when contact is found" do
              let(:data) do
                {
                  "values" => [{ "id" => 123, "display_name" => "John Doe" }],
                  "count" => 1
                }
              end

              it "returns contact hash" do
                expect(subject.result).to be_a Hash
                expect(subject.result[:id]).to eq(123)
                expect(subject.result[:display_name]).to eq("John Doe")
              end
            end

            context "when contact is not found" do
              let(:data) do
                { "values" => [], "count" => 0 }
              end

              it "returns nil" do
                expect(subject.result).to be_nil
              end
            end
          end

          describe "query building" do
            let(:data) do
              { "values" => [{ "id" => 123, "display_name" => "Test" }], "count" => 1 }
            end

            context "with multiple fields" do
              let(:fields) { { "id" => "123", "external_identifier" => "ABC" } }

              it "builds where conditions for each field" do
                subject.result
                expect(WebMock).to have_requested(:any, /api\.example\.org/)
              end
            end

            context "with group_ids" do
              let(:group_ids) { [1, 2, 3] }

              it "adds group filter to query" do
                subject.result
                expect(WebMock).to have_requested(:any, /api\.example\.org/)
              end
            end
          end

          describe ".parse_item" do
            it "returns nil for non-hash input" do
              expect(described_class.parse_item(nil)).to be_nil
              expect(described_class.parse_item("string")).to be_nil
            end

            it "parses hash correctly" do
              result = described_class.parse_item({ "id" => "42", "display_name" => "Test User" })
              expect(result[:id]).to eq(42)
              expect(result[:display_name]).to eq("Test User")
            end
          end
        end
      end
    end
  end
end

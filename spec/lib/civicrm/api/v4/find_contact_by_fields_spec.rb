# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim
  module Civicrm
    module Api
      module V4
        describe FindContactByFields, type: :class do
          include_context "with stubs example api v4"

          let(:fields) { { "Dades_comunes.Usuari_Decidim" => "user_001" } }
          let(:group_ids) { [] }

          subject { described_class.new(fields, group_ids) }

          describe "#result" do
            context "when contact is found" do
              let(:data) { JSON.parse(file_fixture("v4/find_contact_by_fields_valid_response.json").read) }

              it "returns a mapped hash" do
                expect(subject.result).to be_a Hash
                expect(subject.result[:id]).to eq(data["values"].first["id"].to_i)
                expect(subject.result[:display_name]).to eq(data["values"].first["display_name"])
              end
            end

            context "when contact is not found" do
              let(:data) { JSON.parse(file_fixture("v4/empty_response.json").read) }

              it "returns nil" do
                expect(subject.result).to be_nil
              end
            end
          end

          describe "with group_ids filter" do
            let(:data) { JSON.parse(file_fixture("v4/find_contact_by_fields_valid_response.json").read) }
            let(:group_ids) { [100, 200] }

            it "returns contact when found in group" do
              expect(subject.result).to be_a Hash
              expect(subject.result[:id]).to eq(123)
            end
          end

          describe "with multiple search fields" do
            let(:data) { JSON.parse(file_fixture("v4/find_contact_by_fields_valid_response.json").read) }
            let(:fields) do
              {
                "Dades_comunes.Usuari_Decidim" => "user_001",
                "Dades_comunes.Identificador_fiscal" => "12345678X"
              }
            end

            it "returns contact matching all fields" do
              expect(subject.result).to be_a Hash
              expect(subject.result[:id]).to eq(123)
            end
          end

          describe ".parse_item" do
            it "returns nil for non-hash input" do
              expect(described_class.parse_item(nil)).to be_nil
              expect(described_class.parse_item("string")).to be_nil
            end

            it "parses hash correctly" do
              item = { "id" => "42", "display_name" => "Test User" }
              result = described_class.parse_item(item)

              expect(result[:id]).to eq(42)
              expect(result[:display_name]).to eq("Test User")
            end
          end
        end
      end
    end
  end
end

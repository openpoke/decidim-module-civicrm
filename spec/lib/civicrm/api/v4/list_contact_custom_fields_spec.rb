# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim
  module Civicrm
    module Api
      module V4
        describe ListContactCustomFields, type: :class do
          include_context "with stubs example api v4"

          let(:data) { JSON.parse(file_fixture("v4/list_contact_custom_fields_valid_response.json").read) }

          describe ".first_item" do
            it "returns API response hash" do
              result = described_class.first_item
              expect(result).to be_a Hash
              expect(result["values"]).to be_a Array
            end

            it "returns contact with custom field keys" do
              result = described_class.first_item
              contact = result["values"].first

              expect(contact["id"]).to eq(data["values"].first["id"])
              expect(contact.keys).to include("Dades_comunes.Identificador_fiscal")
              expect(contact.keys).to include("Dades_comunes.Usuari_Decidim")
            end

            it "returns custom field values" do
              result = described_class.first_item
              contact = result["values"].first

              expect(contact["Dades_comunes.Identificador_fiscal"]).to eq("12345678X")
              expect(contact["Dades_comunes.Usuari_Decidim"]).to eq("user_001")
            end
          end

          describe ".search_by" do
            it "returns API response for matching contact" do
              result = described_class.search_by("Dades_comunes.Usuari_Decidim" => "user_001")
              expect(result).to be_a Hash
              expect(result["values"]).to be_a Array
            end
          end

          describe ".parse_item" do
            it "returns item as-is without transformation" do
              item = { "id" => 1, "custom_field" => "value" }
              expect(described_class.parse_item(item)).to eq(item)
            end
          end
        end
      end
    end
  end
end

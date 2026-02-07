# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim
  module Elections
    module Admin
      module Censuses
        describe CivicrmGroupsForm do
          subject { described_class.from_params(attributes).with_context(context) }

          include_context "with stubs example api v4"

          let(:organization) { create(:organization) }
          let(:component) { create(:elections_component, organization: organization) }
          let(:election) { create(:election, component: component) }
          let(:context) { { election: election, current_organization: organization } }

          let!(:group1) { create(:civicrm_group, organization: organization, title: "Group A") }
          let!(:group2) { create(:civicrm_group, organization: organization, title: "Group B") }
          let!(:deleted_group) { create(:civicrm_group, organization: organization, marked_for_deletion: true) }

          let(:data) { JSON.parse(file_fixture("v4/list_contact_custom_fields_valid_response.json").read) }

          let(:attributes) do
            {
              civicrm_group_id: group1.civicrm_group_id,
              verification_field_names: ["Dades_comunes.Usuari_Decidim"]
            }
          end

          describe "validations" do
            context "when civicrm_group_id is present" do
              it { is_expected.to be_valid }
            end

            context "when civicrm_group_id is empty" do
              let(:attributes) { { civicrm_group_id: nil } }

              it { is_expected.not_to be_valid }
            end
          end

          describe "#available_groups" do
            it "returns groups for organization" do
              expect(subject.available_groups).to include(group1, group2)
            end

            it "excludes deleted groups" do
              expect(subject.available_groups).not_to include(deleted_group)
            end

            it "orders by title" do
              expect(subject.available_groups.first).to eq(group1)
            end
          end

          describe "#available_custom_fields" do
            it "returns custom fields extracted from API response keys" do
              fields = subject.available_custom_fields
              expect(fields).to be_a Array
              expect(fields.length).to be > 0
            end

            it "extracts field names from response keys" do
              fields = subject.available_custom_fields
              field_names = fields.map(&:name)

              expect(field_names).to include("Dades_comunes.Identificador_fiscal")
              expect(field_names).to include("Dades_comunes.Usuari_Decidim")
            end

            it "includes the id field" do
              fields = subject.available_custom_fields
              id_field = fields.find { |f| f.name == "id" }

              expect(id_field).to be_present
              expect(id_field.label).to eq("id (Password)")
            end

            it "formats labels as 'key (humanized)'" do
              fields = subject.available_custom_fields
              field = fields.find { |f| f.name == "Dades_comunes.Usuari_Decidim" }

              expect(field.label).to eq("Dades_comunes.Usuari_Decidim (Document number)")
            end

            it "uses i18n translation when available" do
              I18n.backend.store_translations(:en, {
                                                decidim: { civicrm: { censuses: { civicrm_groups: { custom_fields: {
                                                  Dades_comunes: { Usuari_Decidim: "Decidim User ID" }
                                                } } } } }
                                              })

              expect(subject.send(:humanize_field_name, "Dades_comunes.Usuari_Decidim")).to eq("Decidim User ID")
            ensure
              I18n.reload!
            end

            it "falls back to humanized name when no translation" do
              expect(subject.send(:humanize_field_name, "Some_group.Some_field")).to eq("Some group - Some field")
            end

            it "uses Rails.cache for caching" do
              expect(Rails.cache).to receive(:fetch)
                .with("civicrm_custom_fields_#{organization.id}", expires_in: 1.hour)
                .and_call_original

              subject.available_custom_fields
            end

            context "when API returns no contacts" do
              let(:data) { JSON.parse(file_fixture("v4/empty_response.json").read) }

              it "returns empty array" do
                expect(subject.available_custom_fields).to eq([])
              end
            end

            context "when API raises an error" do
              before do
                allow(Decidim::Civicrm::Api::V4::ListContactCustomFields).to receive(:first_item).and_raise(StandardError, "API error")
              end

              it "returns empty array and logs error" do
                expect(Rails.logger).to receive(:error).with(/CiviCRM API error/)
                expect(subject.available_custom_fields).to eq([])
              end
            end
          end

          describe "#census_settings" do
            it "stores civicrm_group_id" do
              settings = subject.census_settings

              expect(settings["civicrm_group_id"]).to eq(group1.civicrm_group_id)
            end

            it "stores verification fields as array of names" do
              settings = subject.census_settings

              expect(settings["verification_fields"]).to eq(["Dades_comunes.Usuari_Decidim"])
            end

            it "filters out invalid field names" do
              attributes[:verification_field_names] = ["Dades_comunes.Usuari_Decidim", "nonexistent_field"]
              settings = subject.census_settings

              expect(settings["verification_fields"]).to eq(["Dades_comunes.Usuari_Decidim"])
            end
          end

          describe "#verification_field_names" do
            context "when attribute is set" do
              let(:attributes) { { verification_field_names: ["custom_field"] } }

              it "returns the attribute value" do
                expect(subject.verification_field_names).to eq(["custom_field"])
              end
            end

            context "when attribute is empty" do
              let(:attributes) { { verification_field_names: [] } }
              let(:election) do
                create(:election, component: component, census_settings: {
                         "verification_fields" => ["persisted_field"]
                       })
              end

              it "falls back to persisted verification_fields" do
                expect(subject.verification_field_names).to eq(["persisted_field"])
              end
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim
  module Elections
    module Censuses
      describe CivicrmGroupsForm do
        subject { described_class.from_params(attributes).with_context(context) }

        include_context "with stubs example api v4"

        let(:organization) { create(:organization) }
        let(:component) { create(:elections_component, organization: organization) }
        let(:election) { create(:election, component: component, census_settings: census_settings) }
        let(:context) { { election: election } }

        let!(:group) { create(:civicrm_group, organization: organization, civicrm_group_id: 100) }

        let(:census_settings) do
          {
            "allowed_group_id" => group.id,
            "verification_fields" => ["Dades_comunes.Usuari_Decidim"]
          }
        end

        let(:attributes) do
          {
            verification_data: { "Dades_comunes.Usuari_Decidim" => "user_001" }
          }
        end

        let(:data) { JSON.parse(file_fixture("v4/find_contact_by_fields_valid_response.json").read) }
        let(:contact_id) { 123 }

        describe "validations" do
          context "when required verification data is blank" do
            let(:attributes) { { verification_data: {} } }

            it { is_expected.not_to be_valid }

            it "adds field required error with translated name" do
              subject.valid?

              expect(subject.errors[:base]).to include(
                I18n.t("decidim.civicrm.censuses.civicrm_groups.field_required",
                       field: subject.humanize_field_name("Dades_comunes.Usuari_Decidim"))
              )
            end
          end

          context "when contact exists in CiviCRM and belongs to group" do
            it { is_expected.to be_valid }
          end

          context "when contact not found in CiviCRM" do
            let(:data) { JSON.parse(file_fixture("v4/empty_response.json").read) }

            it { is_expected.not_to be_valid }

            it "adds invalid error message" do
              subject.valid?

              expect(subject.errors[:base]).to include(
                I18n.t("decidim.civicrm.censuses.civicrm_groups.invalid")
              )
            end
          end

          context "when contact found but not in the authorized group" do
            let(:contact_found_response) do
              { "values" => [{ "id" => 123, "display_name" => "John Doe" }], "count" => 1 }
            end
            let(:empty_group_response) do
              { "values" => [], "count" => 0 }
            end

            before do
              allow(Decidim::Civicrm::Api::V4::Request).to receive(:post) do |_entity, query, _action|
                response = double("response")
                result = if query[:where]&.any? { |w| w.first == "id" }
                           empty_group_response
                         else
                           contact_found_response
                         end
                allow(response).to receive(:response).and_return(result)
                response
              end
            end

            it { is_expected.not_to be_valid }

            it "adds not_in_group error message" do
              subject.valid?

              expect(subject.errors[:base]).to include(
                I18n.t("decidim.civicrm.censuses.civicrm_groups.not_in_group")
              )
            end
          end

          context "when no verification fields are configured" do
            let(:census_settings) do
              {
                "allowed_group_id" => group.id,
                "verification_fields" => []
              }
            end
            let(:attributes) { { verification_data: {} } }

            it { is_expected.not_to be_valid }

            it "adds no_data error" do
              subject.valid?

              expect(subject.errors[:base]).to include(
                I18n.t("decidim.civicrm.censuses.civicrm_groups.no_data")
              )
            end
          end
        end

        describe "#voter_uid" do
          context "when contact is valid" do
            before { subject.valid? }

            it "returns SHA512 hash" do
              expect(subject.voter_uid).to be_present
              expect(subject.voter_uid.length).to eq(128)
            end

            it "is deterministic for same contact and election" do
              first_call = subject.voter_uid
              second_call = subject.voter_uid
              expect(first_call).to eq(second_call)
            end
          end

          context "when contact is invalid" do
            let(:data) { JSON.parse(file_fixture("v4/empty_response.json").read) }

            before { subject.valid? }

            it "returns nil" do
              expect(subject.voter_uid).to be_nil
            end
          end
        end

        describe "#allowed_group_id" do
          it "returns group id from census_settings" do
            expect(subject.allowed_group_id).to eq(group.id)
          end

          context "when census_settings is empty" do
            let(:election) { create(:election, component: component, census_settings: {}) }

            it "returns nil" do
              expect(subject.allowed_group_id).to be_nil
            end
          end
        end

        describe "#verification_fields" do
          it "returns field names from census_settings" do
            expect(subject.verification_fields).to eq(["Dades_comunes.Usuari_Decidim"])
          end

          context "when census_settings is empty" do
            let(:election) { create(:election, component: component, census_settings: {}) }

            it "returns empty array" do
              expect(subject.verification_fields).to eq([])
            end
          end
        end
      end
    end
  end
end

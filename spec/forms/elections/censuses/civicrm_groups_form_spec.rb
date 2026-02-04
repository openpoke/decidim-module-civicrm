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
            "allowed_group_ids" => [group.id],
            "verification_fields" => [
              { "name" => "external_identifier", "label" => "Member ID", "required" => true }
            ]
          }
        end

        let(:attributes) do
          {
            contact_id: "123",
            verification_data: { "external_identifier" => "ABC123" }
          }
        end

        describe "validations" do
          context "when contact_id is blank" do
            let(:attributes) { { contact_id: "" } }

            it { is_expected.not_to be_valid }
          end

          context "when contact exists in CiviCRM" do
            let(:data) do
              {
                "values" => [{ "id" => 123, "display_name" => "John Doe" }],
                "count" => 1
              }
            end

            it { is_expected.to be_valid }
          end

          context "when contact not found in CiviCRM" do
            let(:data) do
              { "values" => [], "count" => 0 }
            end

            it { is_expected.not_to be_valid }

            it "adds error message" do
              subject.valid?
              expect(subject.errors[:base]).to include(
                I18n.t("decidim.elections.censuses.civicrm_groups_form.invalid")
              )
            end
          end
        end

        describe "#voter_uid" do
          let(:data) do
            {
              "values" => [{ "id" => 123, "display_name" => "John Doe" }],
              "count" => 1
            }
          end

          context "when contact is valid" do
            before { subject.valid? }

            it "returns SHA512 hash" do
              expect(subject.voter_uid).to be_present
              expect(subject.voter_uid.length).to eq(128) # SHA512 hex length
            end

            it "is deterministic" do
              uid1 = subject.voter_uid
              uid2 = subject.voter_uid
              expect(uid1).to eq(uid2)
            end
          end

          context "when contact is invalid" do
            let(:data) { { "values" => [], "count" => 0 } }

            before { subject.valid? }

            it "returns nil" do
              expect(subject.voter_uid).to be_nil
            end
          end
        end

        describe "#allowed_group_ids" do
          it "returns group ids from census_settings" do
            expect(subject.allowed_group_ids).to eq([group.id])
          end
        end

        describe "#verification_fields" do
          it "returns fields from census_settings" do
            expect(subject.verification_fields.length).to eq(1)
            expect(subject.verification_fields.first["name"]).to eq("external_identifier")
          end
        end
      end
    end
  end
end

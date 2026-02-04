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
          let(:context) { { election: election } }

          let!(:group1) { create(:civicrm_group, organization: organization, title: "Group A") }
          let!(:group2) { create(:civicrm_group, organization: organization, title: "Group B") }
          let!(:deleted_group) { create(:civicrm_group, organization: organization, marked_for_deletion: true) }

          let(:data) do
            {
              "values" => [
                { "id" => 1, "name" => "custom_field_1", "label" => "Custom Field 1", "data_type" => "String", "custom_group_id" => 1 }
              ],
              "count" => 1,
              "countFetched" => 1
            }
          end

          let(:attributes) do
            {
              allowed_group_ids: [group1.id, group2.id],
              verification_fields: []
            }
          end

          describe "validations" do
            context "when allowed_group_ids is present" do
              it { is_expected.to be_valid }
            end

            context "when allowed_group_ids is empty" do
              let(:attributes) { { allowed_group_ids: [] } }

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
            it "returns custom fields from API" do
              fields = subject.available_custom_fields
              expect(fields).to be_a Array
              expect(fields.first[:name]).to eq("custom_field_1")
            end

            it "caches the result" do
              subject.available_custom_fields
              subject.available_custom_fields
              expect(WebMock).to have_requested(:any, /api\.example\.org/).once
            end
          end

          describe "#census_settings" do
            let(:attributes) do
              {
                allowed_group_ids: [group1.id.to_s, group2.id.to_s, ""],
                verification_fields: [
                  { "name" => "field1", "label" => "Field 1", "enabled" => "1", "required" => "1" },
                  { "name" => "field2", "label" => "Field 2", "enabled" => "", "required" => "" }
                ]
              }
            end

            it "normalizes group_ids" do
              settings = subject.census_settings
              expect(settings["allowed_group_ids"]).to eq([group1.id, group2.id])
            end

            it "filters enabled verification fields" do
              settings = subject.census_settings
              expect(settings["verification_fields"].length).to eq(1)
              expect(settings["verification_fields"].first["name"]).to eq("field1")
            end
          end
        end
      end
    end
  end
end

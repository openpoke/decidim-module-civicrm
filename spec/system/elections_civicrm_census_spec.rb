# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

describe "Elections CiViCRM Groups Census voting" do
  include_context "with stubs example api v4"

  let!(:organization) { create(:organization) }
  let!(:participatory_process) { create(:participatory_process, organization:) }
  let!(:elections_component) { create(:elections_component, participatory_space: participatory_process) }
  let!(:group) { create(:civicrm_group, organization:, civicrm_group_id: 100) }

  let(:verification_fields) do
    [{ "name" => "user_id", "label" => "User ID", "required" => true }]
  end

  let(:census_settings) do
    {
      "allowed_group_id" => group.id,
      "verification_fields" => verification_fields
    }
  end

  let!(:election) do
    create(:election, :ongoing, :published,
           component: elections_component,
           census_settings:,
           census_manifest: "civicrm_groups")
  end

  let!(:question) { create(:election_question, :with_response_options, :voting_enabled, election:) }

  before do
    switch_to_host(organization.host)
  end

  describe "census verification form" do
    it "shows verification form when clicking Vote" do
      visit Decidim::EngineRouter.main_proxy(elections_component).election_path(election)

      click_on "Vote"

      expect(page).to have_content("Verify your identity")
      expect(page).to have_field("User ID")
      expect(page).to have_button("Access")
    end

    context "when user enters valid data" do
      let(:data) { JSON.parse(file_fixture("v4/find_contact_by_fields_valid_response.json").read) }

      it "proceeds to voting" do
        visit Decidim::EngineRouter.main_proxy(elections_component).new_election_vote_path(election)

        fill_in "User ID", with: "user_001"
        click_on "Access"

        expect(page).to have_content(translated(question.body))
      end
    end

    context "when user enters invalid data" do
      let(:data) { JSON.parse(file_fixture("v4/empty_response.json").read) }

      it "shows error message" do
        visit Decidim::EngineRouter.main_proxy(elections_component).new_election_vote_path(election)

        fill_in "User ID", with: "wrong_user"
        click_on "Access"

        expect(page).to have_content("Contact not found in CiViCRM")
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

describe "Elections CiViCRM Groups Census voting" do
  include_context "with stubs example api v4"

  let!(:organization) { create(:organization) }
  let!(:participatory_process) { create(:participatory_process, organization:) }
  let!(:elections_component) { create(:elections_component, participatory_space: participatory_process) }
  let!(:group) { create(:civicrm_group, organization:, civicrm_group_id: 100) }

  let(:census_settings) do
    {
      "civicrm_group_id" => group.civicrm_group_id,
      "verification_fields" => ["user_id"]
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
      expect(page).to have_field("user id")
      expect(page).to have_button("Access")
    end

    context "when user enters valid data and belongs to the group" do
      let(:data) { JSON.parse(file_fixture("v4/find_contact_by_fields_valid_response.json").read) }
      let!(:membership) { create(:civicrm_group_membership, group:, contact: nil, civicrm_contact_id: 123) }

      it "proceeds to voting" do
        visit Decidim::EngineRouter.main_proxy(elections_component).new_election_vote_path(election)

        fill_in "user id", with: "user_001"
        click_on "Access"

        expect(page).to have_content(translated(question.body))
      end
    end

    context "when user enters valid data but does not belong to the group" do
      let(:data) { JSON.parse(file_fixture("v4/find_contact_by_fields_valid_response.json").read) }

      it "shows not in group error" do
        visit Decidim::EngineRouter.main_proxy(elections_component).new_election_vote_path(election)

        fill_in "user id", with: "user_001"
        click_on "Access"

        expect(page).to have_content("Contact does not belong to the authorized group")
      end
    end

    context "when user enters invalid data" do
      let(:data) { JSON.parse(file_fixture("v4/empty_response.json").read) }

      it "shows error message" do
        visit Decidim::EngineRouter.main_proxy(elections_component).new_election_vote_path(election)

        fill_in "user id", with: "wrong_user"
        click_on "Access"

        expect(page).to have_content("Contact not found in CiViCRM")
      end

      it "does not show field-level errors" do
        visit Decidim::EngineRouter.main_proxy(elections_component).new_election_vote_path(election)

        fill_in "user id", with: "wrong_user"
        click_on "Access"

        expect(page).to have_content("Contact not found in CiViCRM")
        expect(page).to have_no_content("There is an error in this field")
      end
    end

    context "when prevent_revoting is enabled and user has already voted" do
      let(:data) { JSON.parse(file_fixture("v4/find_contact_by_fields_valid_response.json").read) }

      let(:census_settings) do
        {
          "civicrm_group_id" => group.civicrm_group_id,
          "verification_fields" => ["user_id"],
          "prevent_revoting" => true
        }
      end

      let!(:membership) { create(:civicrm_group_membership, group:, contact: nil, civicrm_contact_id: 123) }

      let(:voter_uid) do
        Digest::SHA512.hexdigest(
          "civicrm-123-#{election.id}-#{Rails.application.secret_key_base}"
        )
      end

      let!(:existing_vote) do
        create(:election_vote,
               question:,
               response_option: question.response_options.first,
               voter_uid:)
      end

      it "shows already voted error" do
        visit Decidim::EngineRouter.main_proxy(elections_component).new_election_vote_path(election)

        fill_in "user id", with: "user_001"
        click_on "Access"

        expect(page).to have_content("You have already voted in this election")
      end
    end

    context "when prevent_revoting is disabled and user has already voted" do
      let(:data) { JSON.parse(file_fixture("v4/find_contact_by_fields_valid_response.json").read) }
      let!(:membership) { create(:civicrm_group_membership, group:, contact: nil, civicrm_contact_id: 123) }

      let(:voter_uid) do
        Digest::SHA512.hexdigest(
          "civicrm-123-#{election.id}-#{Rails.application.secret_key_base}"
        )
      end

      let!(:existing_vote) do
        create(:election_vote,
               question:,
               response_option: question.response_options.first,
               voter_uid:)
      end

      it "allows access to voting" do
        visit Decidim::EngineRouter.main_proxy(elections_component).new_election_vote_path(election)

        fill_in "user id", with: "user_001"
        click_on "Access"

        expect(page).to have_content(translated(question.body))
      end
    end

    context "when user fills all fields but contact is not found" do
      let(:census_settings) do
        {
          "civicrm_group_id" => group.civicrm_group_id,
          "verification_fields" => %w(Dades_comunes.Usuari_Decidim id)
        }
      end
      let(:data) { JSON.parse(file_fixture("v4/empty_response.json").read) }

      it "shows only flash error without marking any field" do
        visit Decidim::EngineRouter.main_proxy(elections_component).new_election_vote_path(election)

        fill_in "Document number", with: "12345678X"
        fill_in "Password", with: "wrong_password"
        click_on "Access"

        expect(page).to have_content("Contact not found in CiViCRM")
        expect(page).to have_no_content("There is an error in this field")
      end
    end
  end
end

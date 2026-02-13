# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

describe "Admin Elections CiViCRM Groups Census configuration" do
  include_context "with stubs example api v4"

  let!(:organization) { create(:organization) }
  let!(:user) { create(:user, :admin, :confirmed, organization:) }
  let!(:participatory_process) { create(:participatory_process, organization:) }
  let!(:elections_component) { create(:elections_component, participatory_space: participatory_process) }
  let!(:election) { create(:election, :with_questions, component: elections_component) }

  let!(:group1) { create(:civicrm_group, organization:, title: "Voters Group A", civicrm_group_id: 100) }
  let!(:group2) { create(:civicrm_group, organization:, title: "Voters Group B", civicrm_group_id: 200) }
  let!(:deleted_group) { create(:civicrm_group, organization:, title: "Deleted Group", marked_for_deletion: Time.current) }

  let(:data) { JSON.parse(file_fixture("v4/list_contact_custom_fields_valid_response.json").read) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  describe "census configuration page" do
    before do
      visit Decidim::EngineRouter.admin_proxy(elections_component).census_election_path(election)
    end

    it "shows CiViCRM Groups census option in selector" do
      expect(page).to have_select("census-manifest-selector")

      within "#census-manifest-selector" do
        expect(page).to have_content("CiViCRM Contact's Custom fields (dynamic)")
      end
    end

    context "when selecting CiViCRM Groups census" do
      before do
        select "CiViCRM Contact's Custom fields (dynamic)", from: "census-manifest-selector"
      end

      it "shows the census configuration form" do
        expect(page).to have_css(".census-form", wait: 2)
        expect(page).to have_content("CiViCRM Group")
        expect(page).to have_content("Contact fields required")
      end

      it "shows available groups excluding deleted ones in Tom Select" do
        expect(page).to have_css(".census-form", wait: 2)

        within ".census-form" do
          group_select = find_by_id("civicrm_groups_civicrm_group_id", visible: :all)
          select_options = group_select.all("option", visible: :all).map(&:text)
          expect(select_options).to include("Voters Group A")
          expect(select_options).to include("Voters Group B")
          expect(select_options).not_to include("Deleted Group")
        end
      end

      it "shows sync warning message" do
        expect(page).to have_css(".census-form", wait: 2)

        within ".census-form" do
          expect(page).to have_css(".callout.warning")
          expect(page).to have_content("CiViCRM group needs to be synchronized")
        end
      end

      it "shows custom fields multiselect with API data" do
        expect(page).to have_css(".census-form", wait: 2)

        within ".census-form" do
          expect(page).to have_css("#civicrm-verification-fields-selector")
        end
      end

      it "shows the prevent revoting checkbox" do
        expect(page).to have_css(".census-form", wait: 2)

        within ".census-form" do
          expect(page).to have_field("civicrm_groups_prevent_revoting", type: "checkbox")
          expect(page).to have_content("Prevent users from editing their votes")
        end
      end

      it "shows all available custom fields from API in the multiselect" do
        expect(page).to have_css(".census-form", wait: 2)

        # Second .ts-wrapper is the verification fields selector
        all(".ts-wrapper .ts-control").last.click
        expect(page).to have_css(".ts-dropdown-content", wait: 2)

        within ".ts-dropdown-content" do
          expect(page).to have_content("Dades_comunes.Usuari_Decidim (Document number)")
          expect(page).to have_content("Dades_comunes.Identificador_fiscal")
        end
      end
    end
  end

  describe "census preview with configured census" do
    let!(:contact1) { create(:civicrm_contact, organization:) }
    let!(:contact2) { create(:civicrm_contact, organization:) }
    let!(:membership1) { create(:civicrm_group_membership, contact: contact1, group: group1) }
    let!(:membership2) { create(:civicrm_group_membership, contact: contact2, group: group1) }

    let(:census_settings) do
      {
        "civicrm_group_id" => group1.civicrm_group_id,
        "verification_fields" => ["Dades_comunes.Usuari_Decidim"]
      }
    end

    before do
      election.update!(census_manifest: "civicrm_groups", census_settings: census_settings)
      visit Decidim::EngineRouter.admin_proxy(elections_component).census_election_path(election)
    end

    it "displays the configured census with saved settings" do
      expect(page).to have_select("census-manifest-selector", selected: "CiViCRM Contact's Custom fields (dynamic)")
      expect(page).to have_css(".census-form")

      within ".census-form" do
        expect(page).to have_css(".ts-wrapper .ts-control", text: "Voters Group A")
      end
    end

    it "shows the preview table with group members" do
      within "table.table-list tbody" do
        expect(page).to have_css("tr", count: 2)
        expect(page).to have_content(contact1.user.name)
        expect(page).to have_content(contact2.user.name)
      end
    end

    it "shows the total census count" do
      expect(page).to have_content("There are currently 2 people eligible for voting")
    end
  end

  describe "census with prevent_revoting persisted" do
    let(:census_settings) do
      {
        "civicrm_group_id" => group1.civicrm_group_id,
        "verification_fields" => ["Dades_comunes.Usuari_Decidim"],
        "prevent_revoting" => true
      }
    end

    before do
      election.update!(census_manifest: "civicrm_groups", census_settings: census_settings)
      visit Decidim::EngineRouter.admin_proxy(elections_component).census_election_path(election)
    end

    it "shows the prevent revoting checkbox as checked" do
      within ".census-form" do
        expect(page).to have_checked_field("civicrm_groups_prevent_revoting")
      end
    end
  end

  describe "census preview includes members without Decidim accounts" do
    let!(:contact) { create(:civicrm_contact, organization:) }
    let!(:membership_with_account) { create(:civicrm_group_membership, contact:, group: group1) }
    let!(:membership_without_account) do
      create(:civicrm_group_membership, group: group1, contact: nil, civicrm_contact_id: 8001,
                                        extra: { "display_name" => "External Voter", "email" => "external@example.org" })
    end

    let(:census_settings) do
      {
        "civicrm_group_id" => group1.civicrm_group_id,
        "verification_fields" => ["Dades_comunes.Usuari_Decidim"]
      }
    end

    before do
      election.update!(census_manifest: "civicrm_groups", census_settings: census_settings)
      visit Decidim::EngineRouter.admin_proxy(elections_component).census_election_path(election)
    end

    it "shows both members with and without Decidim accounts in the preview" do
      within "table.table-list tbody" do
        expect(page).to have_css("tr", count: 2)
        expect(page).to have_content(contact.user.name)
        expect(page).to have_content("External Voter")
      end
    end

    it "shows the correct total count including members without accounts" do
      expect(page).to have_content("There are currently 2 people eligible for voting")
    end
  end
end

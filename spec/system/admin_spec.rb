# frozen_string_literal: true

require "spec_helper"
require "shared/admin_info_examples"

describe "Decidim CiViCRM Admin section" do
  let!(:organization) { create(:organization, available_authorizations:) }
  let(:available_authorizations) { %w(civicrm civicrm_groups civicrm_membership_types) }
  let!(:user) { create(:user, :admin, :confirmed, organization:) }

  let!(:groups) { create_list(:civicrm_group, 3, organization:) }
  let!(:membership_types) do
    [
      create(:civicrm_membership_type, organization:, civicrm_membership_type_id: 123),
      create(:civicrm_membership_type, organization:, civicrm_membership_type_id: 456),
      create(:civicrm_membership_type, organization:, civicrm_membership_type_id: 789)
    ]
  end

  let!(:contact) { create(:civicrm_contact, organization:) }
  let!(:group_membership) { create(:civicrm_group_membership, contact:, group: groups.first) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_admin.root_path
  end

  it "renders the expected menu" do
    expect(page).to have_content("CiViCRM")

    click_on "CiViCRM"

    within ".sidebar-menu" do
      expect(page).to have_link("Configuration")
      expect(page).to have_link("Groups")
      expect(page).to have_link("Membership Types")
      expect(page).to have_link("Meetings")
      expect(page).to have_link("Meeting registrations")
    end
  end

  describe "Configuration page" do
    let(:config) do
      {
        api: { key: "KEY", secret: "SKEY", url: "URL" },
        send_verification_notifications: true,
        send_meeting_registration_notifications: true,
        publish_meetings_as_events: true,
        publish_meeting_registrations: true,
        block_user_name: true,
        block_user_email: true,
        sign_in_authorizations: %w(civicrm civicrm_membership_types civicrm_groups),
        unauthorized_redirect_url: nil
      }
    end

    before do
      allow(Decidim::Civicrm).to receive_messages(api: config[:api], send_verification_notifications: config[:send_verification_notifications], send_meeting_registration_notifications: config[:send_meeting_registration_notifications], publish_meetings_as_events: config[:publish_meetings_as_events], publish_meeting_registrations: config[:publish_meeting_registrations], block_user_name: config[:block_user_name], block_user_email: config[:block_user_email], sign_in_authorizations: config[:sign_in_authorizations], unauthorized_redirect_url: config[:unauthorized_redirect_url])
      visit decidim_civicrm_admin.info_index_path
    end

    it "loads the page" do
      expect(page).to have_content("CiViCRM Module Configuration")
    end

    it_behaves_like "boolean configuration", :api
    it_behaves_like "boolean configuration", :send_verification_notifications
    it_behaves_like "boolean configuration", :send_meeting_registration_notifications
    it_behaves_like "boolean configuration", :publish_meetings_as_events
    it_behaves_like "boolean configuration", :publish_meeting_registrations
    it_behaves_like "boolean blocks"
    it_behaves_like "sign in authorizations"
    it_behaves_like "sign in unauthorized redirects"
  end

  describe "Groups page" do
    before do
      visit decidim_civicrm_admin.groups_path
    end

    it "loads the page" do
      expect(page).to have_content("Groups")
      expect(page).to have_link("Synchronize all with CiViCRM")

      within ".civicrm-groups" do
        expect(page).to have_content(groups[0].title)
        expect(page).to have_content(groups[1].title)
        expect(page).to have_content(groups[2].title)
      end
    end

    it "filters groups with automatic syncrhonization" do
      visit decidim_civicrm_admin.groups_path(q: { auto_sync_members_eq: "true" })

      expect(page).to have_no_content(groups[0].title)
      expect(page).to have_no_content(groups[1].title)
      expect(page).to have_no_content(groups[2].title)
    end

    it "filters groups without automatic syncrhonization" do
      visit decidim_civicrm_admin.groups_path(q: { auto_sync_members_eq: "false" })

      expect(page).to have_content(groups[0].title)
      expect(page).to have_content(groups[1].title)
      expect(page).to have_content(groups[2].title)
    end
  end

  describe "Group members page" do
    before do
      visit decidim_civicrm_admin.group_path(groups.first)
    end

    it "loads the page" do
      expect(page).to have_content("Group members")
      expect(page).to have_content(groups.first.title)

      within ".civicrm-group-members" do
        expect(page).to have_content(contact.user.name)
        expect(page).to have_content(contact.user.nickname)
      end
    end

    it "has show email button with correct data-dialog-open attribute" do
      within ".civicrm-group-members" do
        expect(page).to have_link("Show email")
      end
    end
  end

  describe "Membership Types page" do
    before do
      visit decidim_civicrm_admin.membership_types_path
    end

    it "loads the page" do
      expect(page).to have_content("Membership Types")
      expect(page).to have_link("Synchronize with CiViCRM")

      within ".civicrm-membership-types" do
        expect(page).to have_content(membership_types[0].civicrm_membership_type_id)
        expect(page).to have_content(membership_types[1].civicrm_membership_type_id)
        expect(page).to have_content(membership_types[2].civicrm_membership_type_id)
        expect(page).to have_content(membership_types[0].name)
        expect(page).to have_content(membership_types[1].name)
        expect(page).to have_content(membership_types[2].name)
      end
    end
  end

  describe "Meetings page" do
    before do
      visit decidim_civicrm_admin.meetings_path
    end

    it "loads the page" do
      expect(page).to have_content("CiViCRM Events")
      expect(page).to have_link("Synchronize all with CiViCRM")
    end
  end

  describe "Meeting registrations" do
    before do
      visit decidim_civicrm_admin.meeting_registrations_path
    end

    it "loads the page" do
      expect(page).to have_content("Meeting registrations synchronization")
      expect(page).to have_link("Synchronize all with CiViCRM")
    end
  end

  describe "Elections census multiselect for CiviCRM groups" do
    let!(:participatory_process) { create(:participatory_process, organization:) }
    let!(:elections_component) { create(:elections_component, participatory_space: participatory_process) }
    let!(:election) { create(:election, :with_questions, component: elections_component) }
    let!(:group_with_sync) { create(:civicrm_group, organization:, title: "Election Group", auto_sync_members: true) }

    before do
      visit Decidim::EngineRouter.admin_proxy(elections_component).census_election_path(election)
    end

    it "shows multiselect when internal_users census with CiviCRM Groups is selected" do
      select "Registered participants (dynamic)", from: "census-manifest-selector"

      expect(page).to have_css(".census-form", wait: 2)

      check "internal_users_authorization_handlers_names_civicrm_groups"

      expect(page).to have_css(".groups_container .ts-wrapper")
    end

    it "allows searching groups in elections census multiselect" do
      select "Registered participants (dynamic)", from: "census-manifest-selector"
      expect(page).to have_css(".census-form", wait: 2)
      check "internal_users_authorization_handlers_names_civicrm_groups"
      expect(page).to have_css(".groups_container .ts-wrapper")

      within ".groups_container" do
        find(".ts-control").click
      end
      find(".groups_container .dropdown-input").fill_in with: "Election"

      within ".ts-dropdown-content" do
        expect(page).to have_content("Election Group", wait: 2)
      end
    end
  end

  describe "Permissions multiselect for CiviCRM groups" do
    let!(:participatory_process) { create(:participatory_process, organization:) }
    let!(:component) { create(:proposal_component, participatory_space: participatory_process) }
    let!(:group_with_sync) { create(:civicrm_group, organization:, title: "Synced Group", auto_sync_members: true) }

    before do
      visit decidim_admin_participatory_processes.components_path(participatory_process)
      within "tr", text: component.name["en"] do
        find("[data-controller='dropdown']").click
        click_on "Manage permissions"
      end
    end

    it "shows multiselect when CiviCRM Groups authorization is checked" do
      check "component_permissions_permissions_create_authorization_handlers_civicrm_groups"
      expect(page).to have_css(".groups_container .ts-wrapper")
    end

    it "allows searching and selecting groups in multiselect" do
      check "component_permissions_permissions_create_authorization_handlers_civicrm_groups"
      expect(page).to have_css(".groups_container .ts-wrapper")

      within ".groups_container" do
        find(".ts-control").click
      end
      find(".groups_container .dropdown-input").fill_in with: "Synced"

      within ".ts-dropdown-content" do
        expect(page).to have_content("Synced Group", wait: 2)
      end
    end
  end

  describe "Meeting registration details page" do
    let(:participatory_process) { create(:participatory_process, organization:) }
    let(:component) { create(:meeting_component, participatory_space: participatory_process) }
    let(:meeting) { create(:meeting, component:) }
    let!(:event_meeting) { create(:civicrm_event_meeting, organization:, meeting:) }
    let(:registration_user) { create(:user, :confirmed, organization:) }
    let!(:registration_contact) { create(:civicrm_contact, user: registration_user, organization:) }
    let!(:meeting_registration) { create(:registration, meeting:, user: registration_user) }
    let!(:event_registration) do
      create(:civicrm_event_registration,
             event_meeting:,
             meeting_registration:,
             extra: {
               "contact" => { "display_name" => registration_user.name, "id" => registration_contact.civicrm_contact_id },
               "participant" => { "status" => "Registered", "register_date" => Time.zone.today.to_s }
             })
    end

    before do
      visit decidim_civicrm_admin.meeting_registration_path(event_meeting)
    end

    it "loads the page with registration" do
      expect(page).to have_content(meeting.title["en"])

      within ".civicrm-event_meeting-registrations" do
        expect(page).to have_content(registration_user.nickname)
      end
    end

    it "has show email button with correct data-dialog-open attribute" do
      within ".civicrm-event_meeting-registrations" do
        expect(page).to have_link("Show email")
      end
    end
  end
end

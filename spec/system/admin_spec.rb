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
        api: { api_key: "KEY", site_key: "SKEY", url: "URL" },
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
end

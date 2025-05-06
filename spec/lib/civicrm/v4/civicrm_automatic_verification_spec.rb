# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
describe "Automatic verification after oauth sign up" do
  context "when a user is registered with omniauth" do
    let!(:user) { create(:user) }

    it "runs the OmniauthUserDataSyncJob" do
      expect do
        ActiveSupport::Notifications.publish(
          "decidim.user.omniauth_registration",
          user_id: user.id,
          identity_id: 1234,
          provider: "civicrm",
          uid: "aaa",
          email: user.email,
          name: "Civicrm User",
          nickname: "civicrm_user",
          avatar_url: "http://www.example.com/foo.jpg",
          raw_data: {}
        )
      end.to have_enqueued_job(Decidim::Civicrm::OmniauthUserDataSyncJob)
    end
  end

  context "when a contact is updated" do
    let!(:contact) { create(:civicrm_contact) }

    it "runs the JoinContactToParticipatorySpacesJob" do
      expect do
        ActiveSupport::Notifications.publish(
          "decidim.civicrm.contact.updated",
          contact_id: contact.id
        )
      end.to have_enqueued_job(Decidim::Civicrm::JoinContactToParticipatorySpacesJob)
    end
  end
end

# rubocop:enable RSpec/DescribeClass

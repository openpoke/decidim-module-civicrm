# frozen_string_literal: true

require "spec_helper"

describe "Authentication", type: :system do
  let(:organization) { create(:organization) }
  let(:omniauth_hash) do
    OmniAuth::AuthHash.new(
      provider: Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME,
      uid: 12_345,
      info: {
        email: "civicrm@example.org",
        name: "CiViCRM User",
        verified: true
      }
    )
  end
  let(:block_user_name) { true }
  let(:block_user_email) { true }
  let(:last_user) { Decidim::User.last }

  before do
    allow(Decidim::Civicrm).to receive(:block_user_name).and_return(block_user_name)
    allow(Decidim::Civicrm).to receive(:block_user_email).and_return(block_user_email)

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:civicrm] = omniauth_hash
    OmniAuth.config.add_camelization "civicrm", "Civicrm"
    OmniAuth.config.request_validation_phase = ->(env) {} if OmniAuth.config.respond_to?(:request_validation_phase)

    switch_to_host(organization.host)
    visit decidim.root_path
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:civicrm] = nil
    OmniAuth.config.camelizations.delete("civicrm")
  end

  shared_examples "uses data from civicrm" do |name = "CiViCRM User", email = "civicrm@example.org"|
    it "authenticates an existing User" do
      find(".sign-in-link").click

      perform_enqueued_jobs do
        click_link "Sign in with Civicrm"
      end

      expect(page).to have_content("Successfully")
      expect(page).to have_content(last_user.name)
      expect(last_user.reload.name).to eq(name)
      expect(last_user.email).to eq(email)
    end
  end

  describe "Sign up" do
    it_behaves_like "uses data from civicrm"
  end

  describe "Sign in" do
    let(:user) { create(:user, :confirmed, name: "My Name", email: "my-email@example.org", organization: organization) }
    let!(:identity) { create(:identity, user: user, provider: Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME, uid: "12345") }

    it_behaves_like "uses data from civicrm"

    context "when only changing the name is allowed" do
      let(:block_user_email) { false }

      it_behaves_like "uses data from civicrm", ["CiViCRM User", "my-email@example.org"]
    end

    context "when only changing the email is allowed" do
      let(:block_user_name) { false }

      it_behaves_like "uses data from civicrm", ["My Name", "civicrm@example.org"]
    end

    context "when no previous identity" do
      let(:identity) { nil }

      it_behaves_like "uses data from civicrm"
    end
  end
end

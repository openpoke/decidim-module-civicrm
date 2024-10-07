# frozen_string_literal: true

require "spec_helper"
require "shared/user_login_examples"

describe "Login data" do
  let(:organization) { create(:organization, available_authorizations:) }
  let(:available_authorizations) { %w(civicrm civicrm_groups civicrm_membership_types) }
  let(:omniauth_hash) do
    OmniAuth::AuthHash.new(
      provider: Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME,
      uid: 12_345,
      info: {
        email: "civicrm@example.org",
        name: "CiViCRM User"
      },
      extra:
    )
  end
  let(:extra) do
    {
      contact: {
        id: 123
      }
    }
  end
  let(:block_user_name) { true }
  let(:block_user_email) { true }
  let(:sign_in_authorizations) { [handler] }
  let(:unauthorized_redirect_url) { nil }
  let(:handler) { nil }

  let(:last_user) { Decidim::User.last }
  let(:authorization) { Decidim::Authorization.find_by(name: handler) }
  let(:user) { create(:user, :confirmed, name: "My Name", nickname: "civicrm_user", email: "my-email@example.org", organization:) }
  let!(:identity) { create(:identity, user:, provider: Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME, uid: "12345") }
  let!(:group) { create(:civicrm_group, organization:, civicrm_group_id: 3) }
  let!(:membership_type) { create(:civicrm_membership_type, organization:, civicrm_membership_type_id: 3) }
  let!(:group_membership) { create(:civicrm_group_membership, civicrm_contact_id: 321, contact: nil, group:) }

  before do
    allow(Decidim::Civicrm).to receive_messages(block_user_name:, block_user_email:, sign_in_authorizations:, unauthorized_redirect_url:)

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:civicrm] = omniauth_hash
    OmniAuth.config.add_camelization "civicrm", "Civicrm"
    OmniAuth.config.request_validation_phase = ->(env) {} if OmniAuth.config.respond_to?(:request_validation_phase)

    switch_to_host(organization.host)
    visit decidim.root_path

    within "#main-bar" do
      click_on "Log in"
    end

    perform_enqueued_jobs do
      click_on "Civicrm"
    end
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:civicrm] = nil
    OmniAuth.config.camelizations.delete("civicrm")
  end

  describe "Sign in" do
    it_behaves_like "uses data from civicrm", { user_name_readonly: true, email_readonly: true }

    context "when only changing the name is allowed" do
      let(:block_user_email) { false }

      it_behaves_like "uses data from civicrm", { name: "CiViCRM User", email: "my-email@example.org", user_name_readonly: true }
    end

    context "when only changing the email is allowed" do
      let(:block_user_name) { false }

      it_behaves_like "uses data from civicrm", { name: "My Name", email: "civicrm@example.org", email_readonly: true }
    end

    context "when no previous identity" do
      let(:identity) { nil }

      it_behaves_like "uses data from civicrm", { user_name_readonly: true, email_readonly: true, accept_terms: true }
    end

    it_behaves_like "sign in authorization permissions"
  end

  describe "Sign up" do
    let(:identity) { nil }
    let(:user) { nil }

    it_behaves_like "uses data from civicrm", { accept_terms: true, user_name_readonly: true, email_readonly: true }

    it_behaves_like "sign up authorization permissions"
  end
end

# frozen_string_literal: true

require "spec_helper"
require "shared/user_login_examples"

describe "Login data", type: :system do
  let(:organization) { create(:organization, available_authorizations: available_authorizations) }
  let(:available_authorizations) { %w(civicrm civicrm_groups civicrm_membership_types) }
  let(:omniauth_hash) do
    OmniAuth::AuthHash.new(
      provider: Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME,
      uid: 12_345,
      info: {
        email: "civicrm@example.org",
        name: "CiViCRM User"
      },
      extra: extra
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
  let(:unauthorized_redirection) { nil }
  let(:handler) { nil }

  let(:last_user) { Decidim::User.last }
  let(:authorization) { Decidim::Authorization.find_by(name: handler) }
  let(:user) { create(:user, :confirmed, name: "My Name", email: "my-email@example.org", organization: organization) }
  let!(:identity) { create(:identity, user: user, provider: Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME, uid: "12345") }
  let!(:group) { create :civicrm_group, organization: organization, civicrm_group_id: 3 }
  let!(:membership_type) { create :civicrm_membership_type, organization: organization, civicrm_membership_type_id: 3 }
  let!(:group_membership) { create :civicrm_group_membership, civicrm_contact_id: 321, contact: nil, group: group }

  before do
    allow(Decidim::Civicrm).to receive(:block_user_name).and_return(block_user_name)
    allow(Decidim::Civicrm).to receive(:block_user_email).and_return(block_user_email)
    allow(Decidim::Civicrm).to receive(:sign_in_authorizations).and_return(sign_in_authorizations)
    allow(Decidim::Civicrm).to receive(:unauthorized_redirection).and_return(unauthorized_redirection)

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:civicrm] = omniauth_hash
    OmniAuth.config.add_camelization "civicrm", "Civicrm"
    OmniAuth.config.request_validation_phase = ->(env) {} if OmniAuth.config.respond_to?(:request_validation_phase)

    switch_to_host(organization.host)
    visit decidim.root_path

    find(".sign-in-link").click

    perform_enqueued_jobs do
      click_link "Sign in with Civicrm"
    end
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:civicrm] = nil
    OmniAuth.config.camelizations.delete("civicrm")
  end

  describe "Sign in" do
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

    it_behaves_like "sign in authorization permissions"
  end

  describe "Sign up" do
    let(:identity) { nil }
    let(:user) { nil }

    it_behaves_like "uses data from civicrm"

    it_behaves_like "sign up authorization permissions"
  end
end

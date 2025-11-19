# frozen_string_literal: true

shared_examples "uses data from civicrm" do |name: "CiViCRM User", email: "civicrm@example.org", user_name_readonly: false, email_readonly: false, accept_terms: false|
  it "has authorization and updates user data" do
    if accept_terms
      expect(page).to have_content("Finish creating your account")
      check "By signing up you agree to the terms of service."
      within "form.new_user" do
        find("*[type=submit]").click
      end
      click_on "Keep unchecked"
    else
      expect(page).to have_content("Successfully")
    end
    perform_enqueued_jobs
    visit decidim.account_path

    expect(page).to have_field("user_name", with: last_user.name, readonly: user_name_readonly)
    expect(page).to have_field("email", with: last_user.email, readonly: email_readonly)
    expect(last_user.reload.name).to eq(name)
    expect(last_user.email).to eq(email)
    expect(Decidim::Authorization.find_by(name: :civicrm)).to be_granted
  end

  context "when no contact id is provided" do
    let(:extra) do
      {}
    end

    it "has no authorization and updates user data" do
      if accept_terms
        expect(page).to have_content("Finish creating your account")
        check "By signing up you agree to the terms of service."
        within "form.new_user" do
          find("*[type=submit]").click
        end
        click_on "Keep unchecked"
      else
        expect(page).to have_content("Successfully")
      end
      perform_enqueued_jobs
      visit decidim.account_path

      expect(page).to have_field("user_name", with: last_user.name, readonly: user_name_readonly)
      expect(page).to have_field("email", with: last_user.email, readonly: email_readonly)
      expect(last_user.reload.name).to eq(name)
      expect(last_user.email).to eq(email)
      expect(Decidim::Authorization.find_by(name: :civicrm)).to be_nil
    end
  end
end

shared_examples "sign up authorization permissions" do
  let(:handler) { :civicrm }

  it "has authorization and is allowed to signup" do
    expect(page).to have_content("Successfully")
    expect(authorization).to be_granted
  end

  context "when no contact id is provided" do
    let(:extra) do
      {}
    end

    it "has no authorization and is not allowed to signup" do
      check "By signing up you agree to the terms of service."
      within "form.new_user" do
        find("*[type=submit]").click
      end
      click_on "Keep unchecked"

      expect(authorization).to be_nil
      expect(page).to have_content("You need to verify your account in order to use this platform as a member.")
      expect(page).to have_content("These authorization methods are required: CiViCRM Membership")
      expect(page).to have_current_path(decidim_verifications.first_login_authorizations_path)
    end
  end

  context "when more than one authorization is required" do
    let(:sign_in_authorizations) { [:civicrm, :civicrm_membership_types, :civicrm_groups] }

    it "has one authorization and is not allowed to signup" do
      check "By signing up you agree to the terms of service."
      within "form.new_user" do
        find("*[type=submit]").click
      end
      click_on "Keep unchecked"

      expect(authorization).to be_granted
      expect(Decidim::Authorization.count).to eq(1)

      expect(page).to have_content("You need to verify your account in order to use this platform as a member.")
      expect(page).to have_content("These authorization methods are required: CiViCRM Membership Types, CiViCRM Groups")
      expect(page).to have_current_path(decidim_verifications.first_login_authorizations_path)
    end

    context "when the other authorizations aren't registered" do
      let(:available_authorizations) { %w(civicrm) }

      it "has one authorization and is allowed to signup" do
        check "By signing up you agree to the terms of service."
        within "form.new_user" do
          find("*[type=submit]").click
        end
        click_on "Keep unchecked"

        expect(authorization).to be_granted
        expect(Decidim::Authorization.count).to eq(1)
        expect(page).to have_no_content("You need to verify your account in order to use this platform as a member.")
      end
    end

    context "when has all the authorizations" do
      let(:extra) do
        {
          contact: {
            id: 321
          },
          memberships: [1, 2, 3]
        }
      end

      it "has all the authorizations and is allowed to signup" do
        click_on "I agree with these terms"

        expect(authorization).to be_granted
        expect(Decidim::Authorization.count).to eq(3)

        expect(page).to have_content("Great! You have accepted the terms of service.")
        expect(page).to have_no_content("You need to verify your account in order to use this platform as a member.")
      end
    end
  end
end

shared_examples "sign in authorization permissions" do
  let(:handler) { :civicrm }
  let!(:component) { create(:dummy_component, organization:) }
  let(:resource) { create(:dummy_resource, component:) }

  before do
    allow_any_instance_of(Decidim::Verifications::AuthorizationsController).to receive(:current_component).and_return(component) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Decidim::Verifications::AuthorizationsController).to receive(:resource).and_return(resource) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Decidim::OnboardingActionMessageCell).to receive(:current_component).and_return(component) # rubocop:disable RSpec/AnyInstance

    onboarding_manager = double(
      "Decidim::OnboardingManager",
      pending_action?: true,
      valid?: true,
      action: "vote",
      action_text: "Vote",
      finished_redirect_path: "/",
      available_authorization_selection_page?: true,
      action_authorized_resources: {},
      expired?: false,
      session_duration: 0,
      component: component,
      finished_verifications?: false,
      model: resource,
      model_name: resource.class.model_name,
      model_title: "Dummy Resource",
      filter_authorizations: []
    )

    allow(Decidim::OnboardingManager).to receive(:new).and_return(onboarding_manager)
  end

  it "has authorization and is allowed to signin" do
    expect(page).to have_content("Successfully")
    expect(authorization).to be_granted
  end

  context "when no contact id is provided" do
    let(:extra) do
      {}
    end

    it "has no authorization and is not allowed to signin" do
      expect(authorization).to be_nil
      expect(page).to have_content("Successfully authenticated from Civicrm account.")
      expect(page).to have_current_path(decidim_verifications.onboarding_pending_authorizations_path)

      visit decidim_verifications.onboarding_pending_authorizations_path
      expect(page).to have_current_path(decidim_verifications.onboarding_pending_authorizations_path)
      visit "/pages"
      expect(page).to have_no_current_path(decidim_verifications.onboarding_pending_authorizations_path)
    end

    context "when user is an admin" do
      let(:user) { create(:user, :admin, :confirmed, name: "My Name", email: "my-email@example.org", organization:) }

      it "has no authorization and is allowed to signin" do
        expect(authorization).to be_nil
        expect(page).to have_no_content("You need to verify your account in order to use this platform as a member.")

        visit decidim_admin.root_path
        expect(page).to have_current_path(decidim_admin.root_path)
      end
    end

    context "when alternative redirection is provided" do
      let(:unauthorized_redirect_url) { "/pages" }

      it "has no authorization and redirects to it" do
        expect(authorization).to be_nil
        expect(page).to have_content("You need to verify your account in order to use this platform as a member.")
        expect(page).to have_content("These authorization methods are required: CiViCRM Membership")
        visit decidim_verifications.onboarding_pending_authorizations_path
        expect(page).to have_current_path(decidim_verifications.onboarding_pending_authorizations_path)

        visit decidim.root_path
        expect(page).to have_current_path("/pages")

        visit "/authorizations"
        expect(page).to have_current_path(decidim_verifications.onboarding_pending_authorizations_path)

        # still possible to verify
        visit decidim_verifications.onboarding_pending_authorizations_path
        expect(page).to have_current_path(decidim_verifications.onboarding_pending_authorizations_path)

        visit "/pages"
        expect(page).to have_current_path("/pages")
      end

      context "and url is not allowed" do
        let(:unauthorized_redirect_url) { "/pages" }

        it "has no authorization and redirects to the default" do
          expect(authorization).to be_nil
          expect(page).to have_content("You need to verify your account in order to use this platform as a member.")
          expect(page).to have_content("These authorization methods are required: CiViCRM Membership")
          visit decidim_verifications.onboarding_pending_authorizations_path
          expect(page).to have_current_path(decidim_verifications.onboarding_pending_authorizations_path)
          visit "/pages"
          expect(page).to have_no_current_path(decidim_verifications.onboarding_pending_authorizations_path)
        end
      end
    end
  end
end

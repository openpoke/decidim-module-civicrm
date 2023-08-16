# frozen_string_literal: true

shared_examples "uses data from civicrm" do |name = "CiViCRM User", email = "civicrm@example.org"|
  it "has authorization and updates user data" do
    expect(page).to have_content("Successfully")
    expect(page).to have_content(last_user.name)
    expect(last_user.reload.name).to eq(name)
    expect(last_user.email).to eq(email)
    expect(Decidim::Authorization.find_by(name: :civicrm)).to be_granted
  end

  context "when no contact id is provided" do
    let(:extra) do
      {}
    end

    it "has no authorization and updates user data" do
      expect(page).to have_content("Successfully")
      expect(page).to have_content(last_user.name)
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
      click_button "I agree with these terms"

      expect(authorization).to be_nil
      expect(page).to have_content("You need to verify your account in order to use this platform as a member.")
      expect(page).to have_content("These authorization methods are required: CiViCRM Membership")
      expect(page).to have_current_path(decidim_verifications.first_login_authorizations_path, ignore_query: true)
    end
  end

  context "when more than one authorization is required" do
    let(:sign_in_authorizations) { [:civicrm, :civicrm_membership_types, :civicrm_groups] }

    it "has one authorization and is not allowed to signup" do
      click_button "I agree with these terms"

      expect(authorization).to be_granted
      expect(Decidim::Authorization.count).to eq(1)

      expect(page).to have_content("You need to verify your account in order to use this platform as a member.")
      expect(page).to have_content("These authorization methods are required: CiViCRM Membership Types, CiViCRM Groups")
      expect(page).to have_current_path(decidim_verifications.first_login_authorizations_path, ignore_query: true)
    end

    context "when the other authorizations aren't registered" do
      let(:available_authorizations) { %w(civicrm) }

      it "has one authorization and is allowed to signup" do
        click_button "I agree with these terms"

        expect(authorization).to be_granted
        expect(Decidim::Authorization.count).to eq(1)
        expect(page).not_to have_content("You need to verify your account in order to use this platform as a member.")
        expect(page).to have_content(last_user.name)
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
        click_button "I agree with these terms"

        expect(authorization).to be_granted
        expect(Decidim::Authorization.count).to eq(3)

        expect(page).to have_content("Great! You have accepted the terms and conditions.")
        expect(page).not_to have_content("You need to verify your account in order to use this platform as a member.")
        expect(page).to have_content(last_user.name)
      end
    end
  end
end

shared_examples "sign in authorization permissions" do
  let(:handler) { :civicrm }

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
      expect(page).to have_content("You need to verify your account in order to use this platform as a member.")
      expect(page).to have_content("These authorization methods are required: CiViCRM Membership")
      expect(page).to have_current_path(decidim_verifications.first_login_authorizations_path, ignore_query: true)

      visit decidim.root_path
      expect(page).to have_current_path(decidim_verifications.first_login_authorizations_path, ignore_query: true)
      visit "/pages"
      expect(page).not_to have_current_path(decidim_verifications.first_login_authorizations_path, ignore_query: true)
    end
  end
end

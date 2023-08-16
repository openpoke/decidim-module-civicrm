# frozen_string_literal: true

shared_examples "boolean configuration" do |attribute|
  it "#{attribute} is enabled" do
    within "[data-civicrm-#{attribute}=\"true\"] td:last-child" do
      expect(page).to have_content("Enabled")
    end
  end

  context "when disabled" do
    let(:config) do
      { attribute => false }
    end

    it "#{attribute} is disabled" do
      within "[data-civicrm-#{attribute}=\"false\"] td:last-child" do
        expect(page).to have_content("Disabled")
      end
    end
  end
end

shared_examples "boolean blocks" do
  it "blocks user name/email" do
    within "[data-civicrm-block_user_name] td:last-child" do
      expect(page).to have_selector(".action-icon.text-success", count: 2)
      expect(page).not_to have_selector(".action-icon.text-muted")
    end
  end

  context "when name disabled" do
    let(:config) do
      {
        block_user_name: false,
        block_user_email: true
      }
    end

    it "blocks one" do
      within "[data-civicrm-block_user_name] td:last-child" do
        expect(page).to have_selector(".action-icon.text-success", count: 1)
        expect(page).to have_selector(".action-icon.text-muted", count: 1)
      end
    end
  end

  context "when both disabled" do
    let(:config) do
      {
        block_user_name: false,
        block_user_email: false
      }
    end

    it "blocks none" do
      within "[data-civicrm-block_user_name] td:last-child" do
        expect(page).not_to have_selector(".action-icon.text-success")
        expect(page).to have_selector(".action-icon.text-muted", count: 2)
      end
    end
  end
end

shared_examples "sign in authorizations" do
  it "shows the selected authorizations" do
    within "[data-civicrm-login_required_authorizations] td:last-child" do
      expect(page).to have_content("CiViCRM Membership")
      expect(page).to have_content("CiViCRM Membership Types")
      expect(page).to have_content("CiViCRM Groups")
    end
  end

  context "when some are not available in the organization" do
    let(:available_authorizations) { %w(civicrm_membership_types) }

    it "shows only the available ones" do
      within "[data-civicrm-login_required_authorizations] td:last-child" do
        expect(page).to have_content("CiViCRM Membership Types")
        expect(page).not_to have_content("CiViCRM Groups")
      end
    end
  end

  context "when none selected" do
    let(:config) do
      {
        sign_in_authorizations: []
      }
    end

    it "shows none" do
      within "[data-civicrm-login_required_authorizations] td:last-child" do
        expect(page).to have_content("")
      end
    end
  end
end

shared_examples "sign in unauthorized redirects" do
  it "shows the default redirect page" do
    within "[data-civicrm-unauthorized_redirect_url] td:last-child" do
      expect(page).to have_content("/authorizations/first_login")
    end
  end

  context "alternative redirect specified" do
    let(:config) do
      {
        unauthorized_redirect_url: "/pages/alternative"
      }
    end

    it "shows none" do
      within "[data-civicrm-unauthorized_redirect_url] td:last-child" do
        expect(page).to have_content("/pages/alternative")
      end
    end
  end

  context "when alternative redirect is not allowed" do
    let(:config) do
      {
        unauthorized_redirect_url: "/authorizations"
      }
    end

    it "shows none" do
      within "[data-civicrm-unauthorized_redirect_url] td:last-child" do
        expect(page).to have_content("/authorizations/first_login")
      end
    end
  end
end

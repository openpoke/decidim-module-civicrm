# frozen_string_literal: true

require "spec_helper"

describe "Restrict user data modification" do
  let(:block_user_name) { false }
  let(:block_user_email) { false }
  let(:user) { create(:user, :confirmed, name: "Old name", email: "old@example.org", organization:) }
  let(:organization) { create(:organization) }
  let!(:identity) { create(:identity, user:, provider: Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME, uid:) }
  let(:uid) { 3 }

  before do
    allow(Decidim::Civicrm).to receive_messages(block_user_name:, block_user_email:)
    # to avoid confirmation link
    allow(Decidim::User).to receive(:reconfirmable).and_return(false)

    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim.account_path
  end

  shared_examples "can change everything" do
    it "allows to change name and email" do
      expect(page).to have_field("user_name", readonly: false)
      expect(page).to have_field("user_email", readonly: false)

      fill_in "user_name", with: "New Name"
      fill_in "user_email", with: "new@example.org"
      click_on "Update account"
      fill_in "Current password", with: "decidim123456789"
      click_on "Update account"
      expect(page).to have_content "Your account was successfully updated"
      expect(user.reload.name).to eq "New Name"
      expect(user.email).to eq "new@example.org"
    end
  end

  it_behaves_like "can change everything"
  
  context "when block user name is enabled" do
    let(:block_user_name) { true }
    
    it "allows to change email but not name" do
      expect(page).to have_field("user_name", readonly: true)
      expect(page).to have_field("user_email", readonly: false)
      execute_script("document.getElementById('user_name').removeAttribute('readonly')")
      
      fill_in "user_name", with: "New Name"
      fill_in "user_email", with: "new@example.org"
      click_on "Update account"
      fill_in "Current password", with: "decidim123456789"
      click_on "Update account"
      expect(page).to have_content "Your account was successfully updated"
      expect(user.reload.name).to eq "Old name"
      expect(user.email).to eq "new@example.org"
    end
  end
  
  context "when block user email is enabled" do
    let(:block_user_email) { true }
    
    it "allows to change name but not email" do
      expect(page).to have_field("user_name", readonly: false)
      expect(page).to have_field("user_email", readonly: true)
      execute_script("document.getElementById('user_email').removeAttribute('readonly')")
      fill_in "user_name", with: "New Name"
      fill_in "user_email", with: "new@example.org"
      click_on "Update account"
      fill_in "Current password", with: "decidim123456789"
      click_on "Update account"
      expect(page).to have_content "Your account was successfully updated"
      expect(user.reload.name).to eq "New Name"
      expect(user.email).to eq "old@example.org"
    end
  end
  
  context "when block user name and email are enabled" do
    let(:block_user_name) { true }
    let(:block_user_email) { true }
    
    it "does not allow to change name or email" do
      expect(page).to have_field("user_name", readonly: true)
      expect(page).to have_field("user_email", readonly: true)
      execute_script("document.getElementById('user_name').removeAttribute('readonly')")
      execute_script("document.getElementById('user_email').removeAttribute('readonly')")
      
      fill_in "user_name", with: "New Name"
      fill_in "user_email", with: "new@example.org"
      click_on "Update account"
      fill_in "Current password", with: "decidim123456789"
      click_on "Update account"
      expect(page).to have_content "Your account was successfully updated"
      expect(user.reload.name).to eq "Old name"
      expect(user.email).to eq "old@example.org"
    end

    context "and not civicrm identity exists" do
      let!(:identity) { nil }

      it_behaves_like "can change everything"
    end
  end
end

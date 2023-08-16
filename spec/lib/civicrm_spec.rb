# frozen_string_literal: true

module Decidim
  describe Civicrm do
    before do
      allow(Civicrm).to receive(:sign_in_authorizations).and_return(sign_in_authorizations)
      allow(Civicrm).to receive(:unauthorized_redirect_url).and_return(unauthorized_redirect_url)
    end

    let(:sign_in_authorizations) { [] }
    let(:unauthorized_redirect_url) { nil }

    it "has a version number" do
      expect(Civicrm::VERSION).not_to be_nil
      expect(Civicrm::DECIDIM_VERSION).not_to be_nil
      expect(Civicrm::COMPAT_DECIDIM_VERSION).not_to be_nil
    end

    it "has a default unauthorized redirect url" do
      expect(Civicrm.unauthorized_url).to eq("/authorizations/first_login")
    end

    %w(/authorizations/first_login /locale/a /authorizations/b /users/c /account/delete/d /users/e /pages/f).each do |path|
      context "when redirect url is specified" do
        let(:unauthorized_redirect_url) { path }

        it "uses the specified url" do
          expect(Civicrm.unauthorized_url).to eq(path), "path=#{path}, unauthorized_url=#{Civicrm.unauthorized_url}"
        end
      end
    end

    %w(/ /authorizations /authorizations/first_login /processes /account).each do |path|
      context "when redirect url is not allowed" do
        let(:unauthorized_redirect_url) { path }

        it "uses the default url" do
          expect(Civicrm.unauthorized_url).to eq("/authorizations/first_login")
        end
      end
    end
  end
end

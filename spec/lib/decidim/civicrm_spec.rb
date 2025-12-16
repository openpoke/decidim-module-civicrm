# frozen_string_literal: true

module Decidim
  describe Civicrm do
    before do
      allow(Civicrm).to receive_messages(sign_in_authorizations:, unauthorized_redirect_url:)
    end

    let(:sign_in_authorizations) { [] }
    let(:unauthorized_redirect_url) { nil }

    it "has a version number" do
      expect(Civicrm::VERSION).not_to be_nil
      expect(Civicrm::DECIDIM_VERSION).not_to be_nil
    end

    it "has a default unauthorized redirect url" do
      expect(Civicrm.unauthorized_url).to eq("/authorizations")
    end

    %w(/locale/a /authorizations/b /users/c /account/delete/d /pages/f).each do |path|
      context "when redirect url is #{path}" do
        let(:unauthorized_redirect_url) { path }

        it "uses the specified url" do
          expect(Civicrm.unauthorized_url).to eq(path), "path=#{path}, unauthorized_url=#{Civicrm.unauthorized_url}"
        end
      end
    end

    %w(/ /authorizations /processes /account).each do |path|
      context "when redirect url #{path} is not allowed" do
        let(:unauthorized_redirect_url) { path }

        it "uses the default url" do
          expect(Civicrm.unauthorized_url).to eq("/authorizations")
        end
      end
    end

    context "when using a full url" do
      let(:unauthorized_redirect_url) { "https://example.com/some-page" }

      it "uses the specified url" do
        expect(Civicrm.unauthorized_url).to eq(unauthorized_redirect_url)
      end
    end
  end
end

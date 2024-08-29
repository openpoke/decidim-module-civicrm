# frozen_string_literal: true

require "spec_helper"
require "omniauth"
require "omniauth/test"
require "shared/shared_contexts"

RSpec.configure do |config|
  config.extend OmniAuth::Test::StrategyMacros, type: :strategy
end

describe OmniAuth::Strategies::Civicrm do
  subject do
    strategy
  end

  include_context "with stubs example api"

  let(:data) { JSON.parse(file_fixture("find_user_valid_response.json").read) }

  let(:access_token) { instance_double("AccessToken", options: {}) }
  let(:parsed_response) { instance_double("ParsedResponse") }
  let(:response) { instance_double("Response", parsed: parsed_response) }
  let(:strategy) do
    described_class.new(
      app,
      "CLIENT_ID",
      "CLIENT_SECRET",
      "https://civicrm.example.org"
    )
  end
  let(:app) do
    lambda do |_env|
      [200, {}, ["Hello."]]
    end
  end
  let(:raw_info_hash) do
    {
      "name" => "Arthur Dent",
      "email" => "foo@example.com",
      "preferred_username" => "Foo Bar",
      "picture" => "http://example.org/avatar.jpeg"
    }
  end

  before do
    allow(strategy).to receive(:access_token).and_return(access_token)
  end

  describe "client options" do
    it "has the correct site" do
      expect(subject.client.site).to eq("https://civicrm.example.org")
    end

    it "has the correct authorize url" do
      expect(subject.client.options[:authorize_url]).to eq("https://civicrm.example.org/oauth2/authorize")
    end

    it "has the correct token url" do
      expect(subject.client.options[:token_url]).to eq("https://civicrm.example.org/oauth2/token")
    end
  end

  describe "#callback_url" do
    it "is a combination of host, script name, and callback path" do
      allow(strategy).to receive_messages(full_host: "https://example.com", script_name: "/sub_uri")

      expect(subject.callback_url).to eq("https://example.com/sub_uri/users/auth/civicrm/callback")
    end
  end

  describe "info" do
    before do
      allow(strategy).to receive(:raw_info).and_return(raw_info_hash)
    end

    it "returns the name" do
      expect(subject.info[:name]).to eq(raw_info_hash["name"])
    end

    it "returns the image" do
      expect(subject.info[:image]).to eq(raw_info_hash["picture"])
    end

    it "returns the email" do
      expect(subject.info[:email]).to eq(raw_info_hash["email"])
    end

    it "returns the nickname" do
      expect(subject.info[:nickname]).to eq("foo_bar")
    end

    context "when nickname already exists" do
      let!(:existing_user) { create(:user, nickname: "foo_bar") }

      it "returns a new valid nickname" do
        expect(subject.info[:nickname]).to eq("foo_bar_2")
      end
    end

    context "when the same user exists" do
      let!(:existing_user) { create(:user, nickname: "foo_bar", email: "bar@example.com") }

      it "returns a new valid nickname" do
        expect(subject.info[:nickname]).to eq("foo_bar_2")
      end
    end
  end
end

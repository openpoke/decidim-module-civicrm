# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm::Verifications
  describe InvalidNotification do
    include_context "when a simple event"

    let(:event_name) { "decidim.events.civicrm_verification.invalid" }
    let(:resource) { create(:user) }

    it_behaves_like "a simple event", true
  end
end

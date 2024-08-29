# frozen_string_literal: true

require "spec_helper"
module Decidim::Civicrm
  describe OmniauthContactSyncJob do
    subject { described_class }

    let(:organization) { create(:organization) }
    let(:user) { create(:user, organization:) }
    let!(:identity) { create(:identity, user:, provider: Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME) }
    let(:data) do
      {
        user_id:,
        uid:,
        raw_data: {
          extra: {
            contact: {
              id: contact_id,
              display_name: "John Doe"
            },
            memberships: []
          }
        }
      }
    end
    let(:uid) { 123 }
    let(:contact_id) { 456 }
    let(:user_id) { user.id }

    it "creates a contact" do
      expect { subject.perform_now(data) }.to change(Contact, :count).from(0).to(1)
      expect(Contact.pluck(:civicrm_contact_id)).to contain_exactly(contact_id)
      expect(Contact.first.extra.symbolize_keys).to eq(data[:raw_data][:extra][:contact])
    end

    context "when contact exists" do
      let!(:contact) { create(:civicrm_contact, user:, organization:, civicrm_contact_id: contact_id, extra: { display_name: "John Smith" }) }

      it "updates existing contact" do
        expect(Contact.first.extra.symbolize_keys).not_to eq(data[:raw_data][:extra][:contact])
        expect { subject.perform_now(data) }.not_to(change(Contact, :count))
        expect(Contact.first.extra.symbolize_keys).to eq(data[:raw_data][:extra][:contact])
      end

      context "and has group memberships" do
        let!(:group) { create(:civicrm_group, organization:) }
        let(:group_membership) { create(:civicrm_group_membership, group:, contact: nil, civicrm_contact_id: contact_id) }

        it "updates existing group memberships" do
          expect(group_membership.contact).to be_nil
          expect { subject.perform_now(data) }.not_to(change(GroupMembership, :count))
          expect(group_membership.reload.contact).to eq(contact)
        end
      end
    end
  end
end

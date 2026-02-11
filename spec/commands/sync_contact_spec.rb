# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  describe SyncContact do
    subject { described_class.new(form) }

    let(:organization) { create(:organization) }
    let(:user) { create(:user, organization:) }
    let(:civicrm_contact_id) { 123 }
    let(:civicrm_uid) { 123 }
    let(:extra) { { "display_name" => "John Doe" } }
    let(:membership_types) { [1, 2] }
    let(:custom_fields) { { "Dades_comunes.Identificador_fiscal" => "12345678X" } }

    let(:form) do
      ContactForm.from_params(
        decidim_organization_id: organization.id,
        decidim_user_id: user.id,
        civicrm_contact_id:,
        civicrm_uid:,
        extra:,
        membership_types:,
        custom_fields:
      )
    end

    context "when everything is ok" do
      it "broadcasts ok" do
        expect { subject.call }.to broadcast(:ok)
      end

      it "creates a new contact" do
        expect { subject.call }.to change(Contact, :count).by(1)
      end

      it "stores custom_fields" do
        subject.call
        contact = Contact.last
        expect(contact.custom_fields).to eq(custom_fields)
      end

      context "when contact already exists" do
        let!(:existing_contact) do
          create(:civicrm_contact,
                 organization:,
                 civicrm_contact_id:,
                 custom_fields: { "old_field" => "old_value" })
        end

        it "updates the existing contact" do
          expect { subject.call }.not_to change(Contact, :count)
        end

        it "updates custom_fields" do
          subject.call
          existing_contact.reload
          expect(existing_contact.custom_fields).to eq(custom_fields)
        end
      end
    end

    context "when custom_fields is not provided" do
      let(:custom_fields) { nil }

      it "creates contact without custom_fields" do
        subject.call
        contact = Contact.last
        expect(contact.custom_fields).to eq({})
      end
    end

    context "when form is invalid" do
      let(:civicrm_contact_id) { nil }

      it "broadcasts invalid" do
        expect { subject.call }.to broadcast(:invalid)
      end

      it "does not create a contact" do
        expect { subject.call }.not_to change(Contact, :count)
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Civicrm
    describe FindGroupMemberByCustomFields do
      subject { described_class.new(group: group, fields: fields) }

      let(:organization) { create(:organization) }
      let(:group) { create(:civicrm_group, organization: organization) }
      let(:custom_fields) do
        {
          "Dades_comunes.Usuari_Decidim" => "user_001",
          "Dades_comunes.Identificador_fiscal" => "12345678X"
        }
      end
      let!(:membership) do
        create(:civicrm_group_membership,
               group: group,
               contact: nil,
               civicrm_contact_id: 123,
               custom_fields: custom_fields)
      end

      context "when searching by a single matching field" do
        let(:fields) { { "Dades_comunes.Usuari_Decidim" => "user_001" } }

        it "finds the membership" do
          expect(subject.query).to include(membership)
        end
      end

      context "when searching by all matching fields" do
        let(:fields) { custom_fields }

        it "finds the membership" do
          expect(subject.query.first).to eq(membership)
        end
      end

      context "when field value does not match" do
        let(:fields) { { "Dades_comunes.Usuari_Decidim" => "wrong_user" } }

        it "returns empty relation" do
          expect(subject.query).to be_empty
        end
      end

      context "when field name does not exist in stored data" do
        let(:fields) { { "Nonexistent.Field" => "value" } }

        it "returns empty relation" do
          expect(subject.query).to be_empty
        end
      end

      context "when membership is in a different group" do
        let(:other_group) { create(:civicrm_group, organization: organization) }
        let(:fields) { { "Dades_comunes.Usuari_Decidim" => "user_001" } }

        subject { described_class.new(group: other_group, fields: fields) }

        it "returns empty relation" do
          expect(subject.query).to be_empty
        end
      end

      context "when group is nil" do
        let(:fields) { { "Dades_comunes.Usuari_Decidim" => "user_001" } }

        subject { described_class.new(group: nil, fields: fields) }

        it "returns empty relation" do
          expect(subject.query).to be_empty
        end
      end

      context "when fields is empty" do
        let(:fields) { {} }

        it "returns empty relation" do
          expect(subject.query).to be_empty
        end
      end

      context "when fields is nil" do
        let(:fields) { nil }

        it "returns empty relation" do
          expect(subject.query).to be_empty
        end
      end

      context "when membership has empty custom_fields" do
        let!(:empty_membership) do
          create(:civicrm_group_membership,
                 group: group,
                 contact: nil,
                 civicrm_contact_id: 456,
                 custom_fields: {})
        end
        let(:fields) { { "Dades_comunes.Usuari_Decidim" => "user_001" } }

        it "does not return the empty membership" do
          results = subject.query
          expect(results).to include(membership)
          expect(results).not_to include(empty_membership)
        end
      end

      context "when multiple memberships match" do
        let!(:another_membership) do
          create(:civicrm_group_membership,
                 group: group,
                 contact: nil,
                 civicrm_contact_id: 789,
                 custom_fields: custom_fields.merge("extra_field" => "extra"))
        end
        let(:fields) { { "Dades_comunes.Usuari_Decidim" => "user_001" } }

        it "returns all matching memberships" do
          results = subject.query
          expect(results).to include(membership)
          expect(results).to include(another_membership)
        end
      end
    end
  end
end

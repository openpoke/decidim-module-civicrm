# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Civicrm
    describe AuthorizedUsers do
      subject { described_class.new(organization:, handler_options:) }

      let(:organization) { create(:organization, available_authorizations:) }
      let(:available_authorizations) { %w(civicrm_groups civicrm_membership_types) }

      let!(:group1) { create(:civicrm_group, organization:, civicrm_group_id: 10) }
      let!(:group2) { create(:civicrm_group, organization:, civicrm_group_id: 20) }
      let!(:group3) { create(:civicrm_group, organization:, civicrm_group_id: 30) }

      let!(:membership_type1) { create(:civicrm_membership_type, organization:, civicrm_membership_type_id: 100) }
      let!(:membership_type2) { create(:civicrm_membership_type, organization:, civicrm_membership_type_id: 200) }

      # Users with contacts
      let!(:user1) { create(:user, :confirmed, organization:) }
      let!(:contact1) { create(:civicrm_contact, user: user1, organization:, membership_types: [100]) }

      let!(:user2) { create(:user, :confirmed, organization:) }
      let!(:contact2) { create(:civicrm_contact, user: user2, organization:, membership_types: [200]) }

      let!(:user3) { create(:user, :confirmed, organization:) }
      let!(:contact3) { create(:civicrm_contact, user: user3, organization:, membership_types: []) }

      # User without contact
      let!(:user4) { create(:user, :confirmed, organization:) }

      # Group memberships
      let!(:group_membership1) { create(:civicrm_group_membership, contact: contact1, group: group1) }
      let!(:group_membership2) { create(:civicrm_group_membership, contact: contact2, group: group2) }
      let!(:group_membership3) { create(:civicrm_group_membership, contact: contact3, group: group1) }

      # Create authorizations for users
      let!(:authorization1) do
        create(:authorization, user: user1, name: "civicrm_groups")
        create(:authorization, user: user1, name: "civicrm_membership_types")
      end
      let!(:authorization2) do
        create(:authorization, user: user2, name: "civicrm_groups")
        create(:authorization, user: user2, name: "civicrm_membership_types")
      end
      let!(:authorization3) do
        create(:authorization, user: user3, name: "civicrm_groups")
        create(:authorization, user: user3, name: "civicrm_membership_types")
      end

      context "when filtering by groups with comma-separated ids" do
        let(:handler_options) do
          {
            "civicrm_groups" => { "options" => { "groups" => "10,20" } }
          }
        end

        it "parses comma-separated group ids correctly" do
          expect(subject.civicrm_groups).to eq(%w(10 20))
        end

        it "returns users belonging to specified groups" do
          result = subject.query
          expect(result).to include(user1)
          expect(result).to include(user2)
          expect(result).not_to include(user4)
        end
      end

      context "when filtering by single group id" do
        let(:handler_options) do
          {
            "civicrm_groups" => { "options" => { "groups" => "10" } }
          }
        end

        it "parses single group id correctly" do
          expect(subject.civicrm_groups).to eq(%w(10))
        end

        it "returns users belonging to specified group" do
          result = subject.query
          expect(result).to include(user1)
          expect(result).to include(user3)
          expect(result).not_to include(user2)
        end
      end

      context "when filtering by membership types with comma-separated ids" do
        let(:handler_options) do
          {
            "civicrm_membership_types" => { "options" => { "membership_types" => "100,200" } }
          }
        end

        it "parses comma-separated membership type ids correctly" do
          expect(subject.civicrm_membership_types).to eq(%w(100 200))
        end

        it "returns users with specified membership types" do
          result = subject.query
          expect(result).to include(user1)
          expect(result).to include(user2)
          expect(result).not_to include(user3)
        end
      end

      context "when filtering by single membership type id" do
        let(:handler_options) do
          {
            "civicrm_membership_types" => { "options" => { "membership_types" => "100" } }
          }
        end

        it "parses single membership type id correctly" do
          expect(subject.civicrm_membership_types).to eq(%w(100))
        end

        it "returns users with specified membership type" do
          result = subject.query
          expect(result).to include(user1)
          expect(result).not_to include(user2)
          expect(result).not_to include(user3)
        end
      end

      context "when filtering by both groups and membership types" do
        let(:handler_options) do
          {
            "civicrm_groups" => { "options" => { "groups" => "10" } },
            "civicrm_membership_types" => { "options" => { "membership_types" => "100" } }
          }
        end

        it "returns users matching both filters" do
          result = subject.query
          expect(result).to include(user1)
          expect(result).not_to include(user2)
          expect(result).not_to include(user3)
        end
      end

      context "when no groups or membership types specified" do
        let(:handler_options) { {} }

        it "returns empty arrays for filters" do
          expect(subject.civicrm_groups).to eq([])
          expect(subject.civicrm_membership_types).to eq([])
        end
      end

      context "when handler_options is nil" do
        let(:handler_options) { nil }

        it "handles nil gracefully" do
          expect(subject.civicrm_groups).to eq([])
          expect(subject.civicrm_membership_types).to eq([])
        end
      end
    end
  end
end

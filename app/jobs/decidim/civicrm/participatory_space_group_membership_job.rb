# frozen_string_literal: true

module Decidim
  module Civicrm
    class ParticipatorySpaceGroupMembershipJob < ApplicationJob
      queue_as :default

      def perform(group_id)
        @group = Decidim::Civicrm::Group.find_by(id: group_id)

        unless @group
          Rails.logger.error "ParticipatorySpaceGroupMembershipJob: ERROR: model not found for group #{group_id}"
          return
        end

        clean_private_memberships
        join_private_memberships
      end

      private

      def clean_private_memberships
        valid_memberships = @group.group_memberships.filter_map { |u| u&.contact&.decidim_user_id }
        @group.group_participatory_spaces.each do |item|
          next unless (space = item.participatory_space)
          next unless space.respond_to?(:members)

          # remove non existing members
          space.members.each do |prv_user|
            prv_user.destroy unless valid_memberships.include?(prv_user.decidim_user_id)
          end
        end
      end

      def join_private_memberships
        @group.group_memberships.filter_map(&:contact_id).each do |contact_id|
          JoinContactToParticipatorySpacesJob.perform_later(contact_id)
        end
      end
    end
  end
end

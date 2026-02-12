# frozen_string_literal: true

module Decidim
  module Civicrm
    module Admin
      class GroupMembersController < Admin::ApplicationController
        include Decidim::Admin::Filterable

        helper Decidim::Messaging::ConversationHelper

        helper_method :group, :members, :all_memberships

        def index; end

        def sync
          SyncGroupMembershipJob.perform_later(membership.civicrm_contact_id, group_id: group.id, member_data: membership.extra)
          flash[:notice] = t("success", scope: "decidim.civicrm.admin.group_members.sync")
          redirect_back fallback_location: decidim_civicrm_admin.group_group_members_path(group_id: group.id)
        end

        private

        def members
          paginate(query.result)
        end

        def group
          return if params[:group_id].blank?

          @group ||= all_groups.find(params[:group_id])
        end

        def all_groups
          @all_groups ||= Group.where(organization: current_organization)
        end

        def per_page
          50
        end

        def membership
          @membership ||= GroupMembership.find_by(id: params[:id], group: group)
        end

        def base_query
          all_memberships
        end

        def all_memberships
          group.group_memberships.order(civicrm_contact_id: :asc)
        end

        # Ransack predicate to use in the search_form_for.
        def search_field_predicate
          :id_or_name_cont
        end

        def filters
          [:has_custom_fields, :has_decidim_user]
        end

        def filters_with_values
          {
            has_custom_fields: [:with_custom_fields, :without_custom_fields],
            has_decidim_user: [:with_decidim_user, :without_decidim_user]
          }
        end
      end
    end
  end
end

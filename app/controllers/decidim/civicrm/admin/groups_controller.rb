# frozen_string_literal: true

module Decidim
  module Civicrm
    module Admin
      class GroupsController < Admin::ApplicationController
        include Decidim::Admin::Filterable

        helper Decidim::Messaging::ConversationHelper

        helper_method :group, :groups, :all_groups, :all_participatory_spaces

        def index
          respond_to do |format|
            format.html
            format.json do
              render json: json_groups
            end
          end
        end

        def sync
          if group.present?
            SyncGroupMembersJob.perform_later(group.id)
            flash[:notice] = t("success", scope: "decidim.civicrm.admin.groups.sync")
            redirect_back fallback_location: decidim_civicrm_admin.group_group_members_path(group)
          else
            SyncAllGroupsJob.perform_later(current_organization.id)
            flash[:notice] = t("success", scope: "decidim.civicrm.admin.groups.sync")
            redirect_back fallback_location: decidim_civicrm_admin.groups_path
          end
        end

        def toggle_auto_sync
          return if group.blank?

          group.auto_sync_members = !group.auto_sync_members
          group.save!
          redirect_back fallback_location: decidim_civicrm_admin.groups_path
        end

        def participatory_spaces
          render json: json_participatory_spaces
        end

        def update
          return unless group.present? && params[:participatory_spaces].respond_to?(:map)

          group.group_participatory_spaces = params[:participatory_spaces].filter_map do |item|
            type, id = item.split(".")
            space = type.safe_constantize&.find_by(id:)
            GroupParticipatorySpace.new(group:, participatory_space: space) if space
          end
          group.save!

          redirect_back fallback_location: decidim_civicrm_admin.group_group_members_path(group)
        end

        private

        def json_groups
          query = groups.where(auto_sync_members: true)
          query = if ids.any?
                    query.where(civicrm_group_id: ids)
                  else
                    query.where("title ILIKE ?", "%#{params[:q]}%")
                  end
          query.map do |item|
            {
              id: item.civicrm_group_id,
              text: item.title
            }
          end
        end

        def ids
          params[:ids]&.split(",") || []
        end

        def json_participatory_spaces
          models = Decidim.participatory_space_manifests.pluck(:model_class_name)
          query = Decidim::SearchableResource.where(resource_type: models, organization: current_organization, locale: current_locale)
          query = query.where("resource_type ILIKE ? OR content_a ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q]

          items = query.order("content_a ASC").map do |item|
            {
              id: "#{item.resource_type}.#{item.resource_id}",
              text: "#{item.resource_type}: #{item.content_a}"
            }
          end

          items.uniq { |i| i[:id] }
        end

        def groups
          paginate(query.result)
        end

        def group
          return if params[:id].blank?

          @group ||= all_groups.find(params[:id])
        end

        def all_groups
          @all_groups ||= Group.where(organization: current_organization).order(auto_sync_members: :desc, title: :asc)
        end

        def per_page
          50
        end

        def base_query
          all_groups
        end

        def filters
          [:has_members, :auto_sync_members_eq]
        end

        def filters_with_values
          {
            has_members: [:with_members, :without_members],
            auto_sync_members_eq: [true, false]
          }
        end
      end
    end
  end
end

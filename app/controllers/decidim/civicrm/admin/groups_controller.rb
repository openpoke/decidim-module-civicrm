# frozen_string_literal: true

module Decidim
  module Civicrm
    module Admin
      class GroupsController < Decidim::Admin::ApplicationController
        include Paginable
        include NeedsPermission

        helper CivicrmHelpers
        helper Decidim::Messaging::ConversationHelper

        helper_method :group, :groups, :members, :all_participatory_spaces

        layout "decidim/admin/civicrm"
        add_breadcrumb_item_from_menu :admin_civicrm_menu

        def index
          # enforce_permission_to :index, :civicrm_groups
          respond_to do |format|
            format.html
            format.json do
              render json: json_groups
            end
          end
        end

        def show
          # enforce_permission_to :show, :civicrm_groups
        end

        def sync
          # enforce_permission_to :update, :civicrm_groups

          if group.present?
            SyncGroupMembersJob.perform_later(group.id)
            flash[:notice] = t("success", scope: "decidim.civicrm.admin.groups.sync")
            redirect_to decidim_civicrm_admin.group_path(group)
          else
            SyncAllGroupsJob.perform_later(current_organization.id)
            flash[:notice] = t("success", scope: "decidim.civicrm.admin.groups.sync")
            redirect_to decidim_civicrm_admin.groups_path
          end

          # TODO: send email when complete?
        end

        def toggle_auto_sync
          # enforce_permission_to :update, :civicrm_groups

          return if group.blank?

          group.auto_sync_members = !group.auto_sync_members
          group.save!
          redirect_to decidim_civicrm_admin.groups_path
        end

        def participatory_spaces
          # enforce_permission_to :update, :civicrm_groups

          render json: json_participatory_spaces
        end

        def update
          # enforce_permission_to :update, :civicrm_groups
          return unless group.present? && params[:participatory_spaces].respond_to?(:map)

          group.group_participatory_spaces = params[:participatory_spaces].filter_map do |item|
            type, id = item.split(".")
            space = type.safe_constantize&.find_by(id:)
            GroupParticipatorySpace.new(group:, participatory_space: space) if space
          end
          group.save!

          redirect_to decidim_civicrm_admin.group_path(group)
        end

        private

        def json_groups
          query = groups.where(auto_sync_members: true)
          query = if params[:ids]
                    query.where(civicrm_group_id: params[:ids])
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

        def json_participatory_spaces
          models = Decidim.participatory_space_manifests.pluck(:model_class_name)
          query = Decidim::SearchableResource.where(resource_type: models, organization: current_organization)
          query = query.where("resource_type ILIKE ? OR content_a ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q]

          items = query.order("content_a='' ASC").map do |item|
            {
              id: "#{item.resource_type}.#{item.resource_id}",
              text: "#{item.resource_type}: #{item.content_a}"
            }
          end

          items.uniq { |i| i[:id] }
        end

        def groups
          paginate(all_groups)
        end

        def group
          return if params[:id].blank?

          @group ||= all_groups.find(params[:id])
        end

        def all_groups
          @all_groups ||= Group.where(organization: current_organization).order(auto_sync_members: :desc, title: :asc)
        end

        def members
          paginate(group.group_memberships.order(Arel.sql("contact_id desc nulls last"), Arel.sql("extra ->>'display_name' ASC")))
        end

        def per_page
          50
        end
      end
    end
  end
end

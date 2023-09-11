# frozen_string_literal: true

module Decidim
  module Civicrm
    class RebuildVerificationsJob < ApplicationJob
      queue_as :default

      def perform(workflow_name, organization_id)
        @workflow_name = workflow_name.to_s
        unless Decidim::Civicrm.authorizations.include?(workflow_name&.to_sym)
          Rails.logger.error "RebuildVerificationsJob: ERROR: workflow_name is not a CiViCRM authorization (#{workflow_name})"
          return
        end

        User.where(organization: organization_id).find_each do |user|
          next unless user.civicrm_identity?

          user.contact&.rebuild!
          perform_auth(user)
        end
      end

      private

      def perform_auth(user)
        handler = Decidim::AuthorizationHandler.handler_for(@workflow_name, user: user)
        return unless handler

        destroy_existing!(user)

        Decidim::Verifications::AuthorizeUser.call(handler, user.organization) do
          on(:ok) do
            Rails.logger.info "RebuildVerificationsJob: Success: created for user #{user.id}"
          end

          on(:invalid) do
            Rails.logger.error "RebuildVerificationsJob: ERROR: failed for user #{user&.id}"
          end
        end
      end

      def destroy_existing!(user)
        Decidim::Authorization.find_by(
          user: user,
          name: @workflow_name
        )&.destroy!
      end
    end
  end
end

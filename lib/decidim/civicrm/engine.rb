# frozen_string_literal: true

require "omniauth/civicrm"
require "deface"

module Decidim
  module Civicrm
    # This is the engine that runs on the public interface of decidim-civicrm.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Civicrm

      # Prepare a zone to create overrides
      # https://edgeguides.rubyonrails.org/engines.html#overriding-models-and-controllers
      # overrides
      config.to_prepare do
        Decidim::User.include(Decidim::Civicrm::CivicrmUserAddons)
        Decidim::Meetings::JoinMeeting.include(Decidim::Civicrm::JoinMeetingOverride)
        Decidim::UpdateAccount.include(Decidim::Civicrm::UpdateAccountOverride)
      end

      # controllers and helpers overrides
      initializer "decidim_civicrm.overrides", after: "decidim.action_controller" do
        config.to_prepare do
          Decidim::ApplicationController.include(Decidim::Civicrm::ForceAuthorization)
          Decidim::Devise::SessionsController.include(Decidim::Civicrm::NeedsCivicrmSnippets)
          Decidim::ApplicationController.include(Decidim::Civicrm::NeedsCivicrmSnippets)
          Decidim::Meetings::RegistrationsController.include(Decidim::Civicrm::MeetingsRegistrationsControllerOverride)
          Decidim::Devise::OmniauthRegistrationsController.include(Decidim::Civicrm::OmniauthRawDataSession)
        end
      end

      routes do
        root to: "authorizations#new"
      end

      initializer "decidim_civicrm.omniauth" do
        next unless Decidim::Civicrm.omniauth && Decidim::Civicrm.omniauth[:enabled].present?

        # ensure external icon is available to avoid break the application (see the implementation of omniauth_helper.rb/oauth_icon)
        Decidim::Civicrm.omniauth[:icon_path] = "media/images/civicrm-icon.png" if Decidim::Civicrm.omniauth[:icon_path].blank?

        # Register the provider with Decidim's omniauth_providers
        Decidim.omniauth_providers[Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME.to_sym] = Decidim::Civicrm.omniauth

        Rails.application.config.middleware.use OmniAuth::Builder do
          provider Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME,
                   client_id: Decidim::Civicrm.omniauth[:client_id],
                   client_secret: Decidim::Civicrm.omniauth[:client_secret],
                   site: Decidim::Civicrm.omniauth[:site],
                   icon_path: Decidim::Civicrm.omniauth[:icon_path],
                   scope: "openid profile email"
        end
      end

      initializer "decidim_civicrm.added_icons" do
        Decidim.icons.register(name: "stop-circle-line", icon: "stop-circle-line", category: "system", description: "", engine: :civicrm)
        Decidim.icons.register(name: "play-circle-line", icon: "play-circle-line", category: "system", description: "", engine: :civicrm)
      end

      initializer "decidim_civicrm.user_contact_sync" do
        # Trigger contact creation & synchronization with internal tables
        ActiveSupport::Notifications.subscribe "decidim.user.omniauth_registration" do |_name, data|
          # sync contact table
          Decidim::Civicrm::OmniauthContactSyncJob.perform_now(data)
          # force name/email if necessary
          Decidim::Civicrm::OmniauthUserDataSyncJob.perform_later(data)
        end
        # Also sync when user logs in with existing identity
        ActiveSupport::Notifications.subscribe "decidim.user.omniauth_login" do |_name, data|
          # sync contact table
          Decidim::Civicrm::OmniauthContactSyncJob.perform_now(data)
          # force name/email if necessary
          Decidim::Civicrm::OmniauthUserDataSyncJob.perform_later(data)
        end
        ActiveSupport::Notifications.subscribe "decidim.civicrm.contact.updated" do |_name, data|
          # Trigger autho-verification after sync a contact
          Decidim::Civicrm::AutoVerificationJob.perform_now(data)
          # Trigger membership as private user in configured participatory spaces
          Decidim::Civicrm::JoinContactToParticipatorySpacesJob.perform_later(data)
        end

        # Trigger participatory spaces private members sync
        ActiveSupport::Notifications.subscribe "decidim.civicrm.group_membership.updated" do |_name, data|
          Decidim::Civicrm::ParticipatorySpaceGroupMembershipJob.perform_later(data)
        end
      end

      initializer "decidim_civicrm.authorizations" do
        next unless Decidim::Civicrm.authorizations

        if Decidim::Civicrm.authorizations.include?(:civicrm)
          # Generic verification method using civicrm contacts
          Decidim::Verifications.register_workflow(:civicrm) do |workflow|
            workflow.form = "Decidim::Civicrm::Verifications::Civicrm"
          end
        end

        if Decidim::Civicrm.authorizations.include?(:civicrm_groups)
          # # Another automated verification method that stores all the groups obtained from civicrm
          Decidim::Verifications.register_workflow(:civicrm_groups) do |workflow|
            workflow.form = "Decidim::Civicrm::Verifications::CivicrmGroups"
            workflow.action_authorizer = "Decidim::Civicrm::Verifications::GroupsActionAuthorizer"

            workflow.options do |options|
              options.attribute :groups, type: :string
            end
          end
        end

        if Decidim::Civicrm.authorizations.include?(:civicrm_membership_types)
          # # Another automated verification method that stores all the memberships obtained from civicrm
          Decidim::Verifications.register_workflow(:civicrm_membership_types) do |workflow|
            workflow.form = "Decidim::Civicrm::Verifications::CivicrmMembershipTypes"
            workflow.action_authorizer = "Decidim::Civicrm::Verifications::MembershipTypesActionAuthorizer"

            workflow.options do |options|
              options.attribute :membership_types, type: :string
            end
          end
        end
      end

      initializer "decidim_civicrm.election_overrides" do
        config.to_prepare do
          next unless defined?(Decidim::Elections)

          # Override the internal_users census to fetch users from CiviCRM
          Decidim::Elections.census_registry.find(:internal_users).user_query do |election|
            Decidim::Civicrm::AuthorizedUsers.new(
              organization: election.organization,
              handler_options: election.census_settings["authorization_handlers"]
            ).query
          end
        end
      end

      initializer "decidim_civicrm.events_sync" do
        # triggers civicrm api submissions for events
        config.to_prepare do
          Decidim::EventsManager.subscribe(/^decidim\.events\./) do |event_name, data|
            Decidim::Civicrm::EventSyncJob.perform_later(event_name, data)
          end
        end
      end

      # Register CiViCRM Groups Census for Elections
      initializer "decidim_civicrm.elections_census", after: "decidim.elections.default_censuses" do
        next unless Decidim.const_defined?(:Elections)

        Decidim::Elections.census_registry.register(:civicrm_groups) do |manifest|
          manifest.admin_form = "Decidim::Elections::Admin::Censuses::CivicrmGroupsForm"
          manifest.admin_form_partial = "decidim/elections/admin/censuses/civicrm_groups_form"
          manifest.voter_form = "Decidim::Elections::Censuses::CivicrmGroupsForm"
          manifest.voter_form_partial = "decidim/elections/censuses/civicrm_groups_form"

          manifest.user_query do |election|
            group_id = election.census_settings&.dig("civicrm_group_id")
            next Decidim::Civicrm::GroupMembership.none unless group_id

            group = Decidim::Civicrm::Group.find_by(civicrm_group_id: group_id)
            next Decidim::Civicrm::GroupMembership.none unless group

            group.group_memberships
          end

          # census is dynamic, so we do not need to validate it
          manifest.census_ready_validator do |_election|
            true
          end
        end
      end
    end
  end
end

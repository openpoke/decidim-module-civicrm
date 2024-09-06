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
        # omniauth only trigger notifications when a new user is registered
        # this adds a notification too when user logs in
        Decidim::CreateOmniauthRegistration.include(Decidim::Civicrm::CreateOmniauthRegistrationOverride)
        Decidim::Meetings::JoinMeeting.include(Decidim::Civicrm::JoinMeetingOverride)
        Decidim::UpdateAccount.include(Decidim::Civicrm::UpdateAccountOverride)
      end

      # controllers and helpers overrides
      initializer "decidim_civicrm.overrides", after: "decidim.action_controller" do
        config.to_prepare do
          Decidim::ApplicationController.include(Decidim::Civicrm::ForceAuthorization)
          Decidim::Devise::SessionsController.include(Decidim::Civicrm::NeedsCivicrmSnippets)
          Decidim::ApplicationController.include(Decidim::Civicrm::NeedsCivicrmSnippets)
          Decidim::Admin::ResourcePermissionsController.include(Decidim::Civicrm::Admin::NeedsMultiselectSnippets)
          Decidim::Meetings::RegistrationsController.include(Decidim::Civicrm::MeetingsRegistrationsControllerOverride)
        end
      end

      routes do
        root to: "authorizations#new"
      end

      initializer "decidim_civicrm.omniauth" do
        next unless Decidim::Civicrm.omniauth && Decidim::Civicrm.omniauth[:enabled].present?

        # Decidim use the secrets configuration to decide whether to show the omniauth provider
        Rails.application.secrets[:omniauth][Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME.to_sym] = Decidim::Civicrm.omniauth
        # ensure external icon is available to avoid break the aplication (see the implementati0on of omniauth_helper.rb/oauth_icon)
        Decidim::Civicrm.omniauth[:icon_path] = "media/images/civicrm-icon.png" unless Decidim::Civicrm.omniauth[:icon_path].present?

        Rails.application.config.middleware.use OmniAuth::Builder do
          provider Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME,
                   client_id: Decidim::Civicrm.omniauth[:client_id],
                   client_secret: Decidim::Civicrm.omniauth[:client_secret],
                   site: Decidim::Civicrm.omniauth[:site],
                   icon_path: Decidim::Civicrm.omniauth[:icon_path],
                   scope: "openid profile email"
        end
      end

      initializer "decidim_civicrm.user_contact_sync" do
        # Trigger contact creation & synchronization with internal tables
        ActiveSupport::Notifications.subscribe "decidim.user.omniauth_registration" do |_name, data|
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

      initializer "decidim_civicrm.events_sync" do
        # triggers civicrm api submissions for events
        Decidim::EventsManager.subscribe(/^decidim\.events\./) do |event_name, data|
          Decidim::Civicrm::EventSyncJob.perform_later(event_name, data)
        end
      end
    end
  end
end

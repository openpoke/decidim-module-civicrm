# frozen_string_literal: true

require "decidim/civicrm/admin"
require "decidim/civicrm/admin_engine"
require "decidim/civicrm/api"
require "decidim/civicrm/event_parsers"
require "decidim/civicrm/engine"
require "decidim/civicrm/verifications"
require "decidim/civicrm/version"

module Decidim
  # This namespace holds the logic of the `decidim-civicrm` module.
  module Civicrm
    include ActiveSupport::Configurable
    def self.to_bool(val)
      ActiveRecord::Type::Boolean.new.deserialize(val.to_s.downcase)
    end

    OMNIAUTH_PROVIDER_NAME = "civicrm"

    # setup API credentials
    config_accessor :api do
      {
        api_key: ENV["CIVICRM_API_KEY"].to_s.presence,
        site_key: ENV["CIVICRM_SITE_KEY"].to_s.presence,
        url: ENV["CIVICRM_API_URL"].to_s.presence
      }
    end

    # setup a hash with :client_id, :client_secret and :site to enable omniauth authentication
    config_accessor :omniauth do
      {
        enabled: ENV["CIVICRM_CLIENT_ID"].present?,
        client_id: ENV["CIVICRM_CLIENT_ID"].presence,
        client_secret: ENV["CIVICRM_CLIENT_SECRET"].presence,
        site: ENV["CIVICRM_SITE"].presence,
        icon_path: ENV["CIVICRM_ICON"].presence || "media/images/civicrm-icon.png"
      }
    end

    # authorizations enabled
    config_accessor :authorizations do
      [:civicrm, :civicrm_groups, :civicrm_membership_types]
    end

    # if false, no notifications will be send to users when automatic verifications are performed
    config_accessor :send_verification_notifications do
      ENV.has_key?("CIVICRM_VERIFICATION_NOTIFICATIONS") ? Decidim::Civicrm.to_bool(ENV["CIVICRM_VERIFICATION_NOTIFICATIONS"]) : true
    end

    # array with civirm group ids that will automatically (cron based) syncronize contact memberships
    # note that admins can override these groups in the app
    config_accessor :default_sync_groups do
      []
    end

    # Set it true to create a new event in CiViCRM automatically every time a new meeting is created in Decidim
    # set to false to disable this functionality
    config_accessor :publish_meetings_as_events do
      Decidim::Civicrm.to_bool(ENV["CIVICRM_PUBLISH_MEETINGS"])
    end

    # If you have some custom fields in your CiVICRM events and want them in the Decidim database
    # set extra attributes to send when creating a event from a meeting in CiViCRM
    # ie:
    # { template_id: 2 }
    config_accessor :publish_extra_event_attributes do
      {}
    end

    # unless false, meeting registrations will be posted to CiViCRM and syncronized back according to the status
    # It requires to the admin to pair each Decidim meeting with a CiVICRM event.
    # (This happens automatically if publish_meetings_as_events is true)
    # set to false to disable this functionality
    config_accessor :publish_meeting_registrations do
      ENV.has_key?("CIVICRM_PUBLISH_MEETING_REGISTRATIONS") ? Decidim::Civicrm.to_bool(ENV["CIVICRM_PUBLISH_MEETING_REGISTRATIONS"]) : true
    end

    # if false, no notifications will be send to users when joining a meeting
    config_accessor :send_meeting_registration_notifications do
      ENV.has_key?("CIVICRM_REGISTRATION_NOTIFICATIONS") ? Decidim::Civicrm.to_bool(ENV["CIVICRM_REGISTRATION_NOTIFICATIONS"]) : true
    end

    # does not allow users with a civicrm omniauth identity to change their user name (real name)
    # This parameter also changes the name to the one provided by Omniauth (if any) everytime the user logs in
    config_accessor :block_user_name do
      Decidim::Civicrm.to_bool(ENV.fetch("CIVICRM_BLOCK_USER_NAME", nil))
    end

    # does not allow users with a civicrm omniauth identity to change their email
    # This parameter also changes the email to the one provided by Omniauth (if any) everytime the user logs in
    config_accessor :block_user_email do
      Decidim::Civicrm.to_bool(ENV.fetch("CIVICRM_BLOCK_USER_EMAIL", nil))
    end

    class Error < StandardError; end
  end
end

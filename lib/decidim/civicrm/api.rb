# frozen_string_literal: true

require_relative "api/base/base_query"
require_relative "api/base/v3/base_query"
require_relative "api/base/v3/find_query"
require_relative "api/base/v3/list_query"
require_relative "api/base/v3/request"
require_relative "api/base/v4/base_query"
require_relative "api/base/v4/find_query"
require_relative "api/base/v4/list_query"
require_relative "api/base/v4/request"
require_relative "api/find_contact"
require_relative "api/find_event"
require_relative "api/find_group"
require_relative "api/find_participant"
require_relative "api/find_user"
require_relative "api/list_contact_groups"
require_relative "api/list_contact_memberships"
require_relative "api/list_contacts_in_group"
require_relative "api/list_groups"
require_relative "api/list_membership_types"
require_relative "api/participants_in_event"
require_relative "api/request"
require_relative "api/list_events"
require_relative "api/v3/find_contact"
require_relative "api/v3/find_event"
require_relative "api/v3/find_group"
require_relative "api/v3/find_participant"
require_relative "api/v3/find_user"
require_relative "api/v3/list_contact_groups"
require_relative "api/v3/list_contact_memberships"
require_relative "api/v3/list_contacts_in_group"
require_relative "api/v3/list_groups"
require_relative "api/v3/list_membership_types"
require_relative "api/v3/participants_in_event"
require_relative "api/v3/list_events"
require_relative "api/v4/find_contact"
require_relative "api/v4/find_event"
require_relative "api/v4/find_group"
require_relative "api/v4/find_participant"
require_relative "api/v4/find_user"
require_relative "api/v4/list_contact_groups"
require_relative "api/v4/list_contact_memberships"
require_relative "api/v4/list_contacts_in_group"
require_relative "api/v4/list_groups"
require_relative "api/v4/list_membership_types"
require_relative "api/v4/participants_in_event"
require_relative "api/v4/list_events"

module Decidim
  module Civicrm
    # This namespace holds the logic to connect to the CiViCRM REST API.
    module Api
      def self.config
        Decidim::Civicrm.api
      end

      def self.credentials
        {
          api_key: config[:api_key],
          key: config[:site_key]
        }
      end

      def self.url
        config[:url]
      end

      def self.version
        config[:version]
      end

      def self.available_versions
        @available_versions ||= {
          v3: "V3",
          v4: "V4"
        }
      end
    end
  end
end

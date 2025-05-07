# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V3
        autoload :Request, "decidim/civicrm/api/v3/request"
        autoload :BaseQuery, "decidim/civicrm/api/v3/base_query"
        autoload :FindQuery, "decidim/civicrm/api/v3/find_query"
        autoload :ListQuery, "decidim/civicrm/api/v3/list_query"
        autoload :FindContact, "decidim/civicrm/api/v3/find_contact"
        autoload :FindEvent, "decidim/civicrm/api/v3/find_event"
        autoload :FindGroup, "decidim/civicrm/api/v3/find_group"
        autoload :FindParticipant, "decidim/civicrm/api/v3/find_participant"
        autoload :FindUser, "decidim/civicrm/api/v3/find_user"
        autoload :ListEvents, "decidim/civicrm/api/v3/list_events"
        autoload :ListContactGroups, "decidim/civicrm/api/v3/list_contact_groups"
        autoload :ListContactMemberships, "decidim/civicrm/api/v3/list_contact_memberships"
        autoload :ListGroupContacts, "decidim/civicrm/api/v3/list_group_contacts"
        autoload :ListGroups, "decidim/civicrm/api/v3/list_groups"
        autoload :ListMembershipTypes, "decidim/civicrm/api/v3/list_membership_types"
        autoload :ListEventParticipants, "decidim/civicrm/api/v3/list_event_participants"
      end
    end
  end
end

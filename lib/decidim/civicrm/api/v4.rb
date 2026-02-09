# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        autoload :Request, "decidim/civicrm/api/v4/request"
        autoload :BaseQuery, "decidim/civicrm/api/v4/base_query"
        autoload :FindQuery, "decidim/civicrm/api/v4/find_query"
        autoload :ListQuery, "decidim/civicrm/api/v4/list_query"
        autoload :ListEvents, "decidim/civicrm/api/v4/list_events"
        autoload :FindContact, "decidim/civicrm/api/v4/find_contact"
        autoload :FindEvent, "decidim/civicrm/api/v4/find_event"
        autoload :FindGroup, "decidim/civicrm/api/v4/find_group"
        autoload :FindParticipant, "decidim/civicrm/api/v4/find_participant"
        autoload :FindUser, "decidim/civicrm/api/v4/find_user"
        autoload :ListContactGroups, "decidim/civicrm/api/v4/list_contact_groups"
        autoload :ListContactMemberships, "decidim/civicrm/api/v4/list_contact_memberships"
        autoload :ListContactCustomFields, "decidim/civicrm/api/v4/list_contact_custom_fields"
        autoload :ListGroupContacts, "decidim/civicrm/api/v4/list_group_contacts"
        autoload :ListGroups, "decidim/civicrm/api/v4/list_groups"
        autoload :ListMembershipTypes, "decidim/civicrm/api/v4/list_membership_types"
        autoload :ListEventParticipants, "decidim/civicrm/api/v4/list_event_participants"
        autoload :ListContactCustomFields, "decidim/civicrm/api/v4/list_contact_custom_fields"
        autoload :FindContactByFields, "decidim/civicrm/api/v4/find_contact_by_fields"
      end
    end
  end
end

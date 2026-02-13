# frozen_string_literal: true

module Decidim
  module Civicrm
    # Finds group memberships by matching custom field values within a specific group.
    # Uses PostgreSQL JSONB containment operator (@>) for lookup.
    #
    # Returns an ActiveRecord relation of matching GroupMembership records.
    class FindGroupMemberByCustomFields < Decidim::Query
      def initialize(group:, fields:)
        @group = group
        @fields = fields
      end

      def query
        return GroupMembership.none if @group.blank? || @fields.blank?

        @group.group_memberships.where("custom_fields @> ?", @fields.to_json)
      end
    end
  end
end

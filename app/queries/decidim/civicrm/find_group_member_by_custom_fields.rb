# frozen_string_literal: true

module Decidim
  module Civicrm
    # Finds group memberships by matching custom field values within a specific group.
    # Checks if all provided field values match within the stored custom_fields JSONB.
    #
    # Returns an ActiveRecord relation of matching GroupMembership records.
    class FindGroupMemberByCustomFields < Decidim::Query
      def initialize(group:, fields:)
        @group = group
        @fields = fields
      end

      def query
        return GroupMembership.none if @group.blank? || @fields.blank?

        # Build conditions to check if each field key-value pair exists in custom_fields JSONB
        conditions = @fields.map do |_key, _value|
          "custom_fields ->> ? = ?"
        end.join(" AND ")

        @group.group_memberships.where(conditions, *@fields.flat_map { |k, v| [k, v] })
      end
    end
  end
end

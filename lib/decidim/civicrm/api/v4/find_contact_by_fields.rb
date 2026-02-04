# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        # Finds a contact by field values with optional group membership check.
        # Used for Elections census verification.
        class FindContactByFields < FindQuery
          def initialize(fields, group_ids = [])
            @fields = fields
            @group_ids = group_ids
            @request = Request.post("Contact", build_query, "get")

            store_result
          end

          def self.parse_item(item)
            return nil unless item.is_a?(Hash)

            {
              id: item["id"].to_i,
              display_name: item["display_name"]
            }
          end

          private

          def build_query
            query = {
              select: %w(id display_name),
              where: build_where_conditions,
              limit: 1
            }

            add_group_filter(query) if @group_ids.present?
            query
          end

          def build_where_conditions
            @fields.map { |field, value| [field.to_s, "=", value] }
          end

          def add_group_filter(query)
            query[:join] = [["GroupContact AS gc", "INNER", %w(gc.contact_id = id)]]
            query[:where] << ["gc.group_id", "IN", @group_ids]
            query[:where] << %w(gc.status = Added)
          end
        end
      end
    end
  end
end

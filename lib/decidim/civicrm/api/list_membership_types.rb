# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      class ListMembershipTypes
        attr_reader :result

        def initialize(query = nil)
          @result = case Decidim::Civicrm::Api.version
                    when Decidim::Civicrm::Api.available_versions[:v3]
                      Decidim::Civicrm::Api::V3::ListMembershipTypes.new(query).result
                    when Decidim::Civicrm::Api.available_versions[:v4]
                      Decidim::Civicrm::Api::V4::ListMembershipTypes.new(query).result
                    end
        end
      end
    end
  end
end

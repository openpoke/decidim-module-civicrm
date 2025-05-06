# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      class ListGroups
        attr_reader :result

        def initialize(query = nil)
          @result = case Decidim::Civicrm::Api.version
                    when Decidim::Civicrm::Api.available_versions[:v3]
                      Decidim::Civicrm::Api::V3::ListGroups.new(query).result
                    when Decidim::Civicrm::Api.available_versions[:v4]
                      Decidim::Civicrm::Api::V4::ListGroups.new(query).result
                    end
        end
      end
    end
  end
end

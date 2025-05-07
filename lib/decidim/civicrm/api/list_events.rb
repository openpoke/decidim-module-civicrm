# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      class ListEvents
        attr_reader :result

        def initialize(query = nil)
          @result = case Decidim::Civicrm::Api.version
                    when Decidim::Civicrm::Api.available_versions[:v3]
                      Decidim::Civicrm::Api::V3::ListEvents.new(query).result
                    when Decidim::Civicrm::Api.available_versions[:v4]
                      Decidim::Civicrm::Api::V4::ListEvents.new(query).result
                    end
        end
      end
    end
  end
end

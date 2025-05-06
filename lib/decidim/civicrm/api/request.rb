# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      class Request
        def self.post(data)
          case Decidim::Civicrm::Api.version
          when Decidim::Civicrm::Api.available_versions[:v3]
            Decidim::Civicrm::Api::Base::V3::Request.post(data, verify_ssl: true)
          when Decidim::Civicrm::Api.available_versions[:v4]
            entity = data[:entity]
            action = data[:action]
            data.delete(:entity)
            data.delete(:action)
            data.delete(:json)
            Decidim::Civicrm::Api::Base::V4::Request.post(entity, data, action, verify_ssl: true)
          end
        end
      end
    end
  end
end

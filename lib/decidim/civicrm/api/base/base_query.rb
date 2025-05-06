# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module Base
        class BaseQuery
          attr_reader :result, :request

          def success?
            return true if response.has_key?("values")

            raise Decidim::Civicrm::Error, "Malformed response for #{self.class.name}: #{response.to_json}"
          end

          def response
            @request.response
          end

          def self.to_bool(val)
            Decidim::Civicrm.to_bool(val)
          end

          protected

          def parsed_response
            raise NotImplementedError
          end

          def default_query
            raise NotImplementedError
          end
        end
      end
    end
  end
end

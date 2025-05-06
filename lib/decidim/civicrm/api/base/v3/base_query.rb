# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module Base
        module V3
          class BaseQuery < Base::BaseQuery
            attr_reader :result, :request

            protected

            def json_params(params)
              params.merge(
                sequential: 1
              ).to_json
            end

            def store_result
              return unless success?

              @result = parsed_response
              @result = @result.deep_symbolize_keys if @result.is_a? Hash
            end
          end
        end
      end
    end
  end
end

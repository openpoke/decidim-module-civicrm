# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module Base
        module V4
          class BaseQuery < Base::BaseQuery
            attr_reader :result, :request

            def store_result
              return unless success?

              @result = parsed_response
              @result[:values] = @result[:values].deep_symbolize_keys if @result[:values].is_a? Hash
            end
          end
        end
      end
    end
  end
end

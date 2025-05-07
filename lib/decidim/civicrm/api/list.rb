# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      class List
        attr_reader :result

        def initialize(entity, id = nil, query = nil)
          klass_name = "Decidim::Civicrm::Api::V#{Decidim::Civicrm::Api.version}::List#{entity.camelize}"
          klass = klass_name.constantize

          @result ||= klass.new(id, query).result
        end
      end
    end
  end
end

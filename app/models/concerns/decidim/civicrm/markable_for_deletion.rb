# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Civicrm
    module MarkableForDeletion
      extend ActiveSupport::Concern

      included do
        scope :to_delete, -> { where.not(marked_for_deletion: nil) }
        scope :to_keep, -> { where(marked_for_deletion: nil) }
      end

      class_methods do
        # rubocop:disable Rails/SkipsModelValidations

        def prepare_cleanup(query = {}, sync_id:)
          where(query).update_all(marked_for_deletion: sync_id)
        end

        def clean_up_records(query = {}, sync_id: nil)
          scope = where(query)
          scope = sync_id.nil? ? scope.to_delete : scope.where(marked_for_deletion: sync_id)
          scope.destroy_all
        end

        # rubocop:enable Rails/SkipsModelValidations
      end
    end
  end
end

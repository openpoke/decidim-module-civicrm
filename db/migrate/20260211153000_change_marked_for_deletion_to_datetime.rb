# frozen_string_literal: true

class ChangeMarkedForDeletionToDatetime < ActiveRecord::Migration[5.2]
  TABLES = [
    :decidim_civicrm_contacts,
    :decidim_civicrm_groups,
    :decidim_civicrm_group_memberships,
    :decidim_civicrm_membership_types,
    :decidim_civicrm_event_meetings,
    :decidim_civicrm_event_registrations
  ].freeze

  def change
    TABLES.each do |table|
      change_column table,
                    :marked_for_deletion,
                    :datetime,
                    default: nil,
                    null: true,
                    using: "NULL"
    end
  end
end

# frozen_string_literal: true

class CreateDecidimCivicrmEventRegistrations < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_civicrm_event_registrations do |t|
      t.references :event_meeting, null: false, foreign_key: { to_table: :decidim_civicrm_event_meetings }, index: { name: :index_decidim_civicrm_event_registrations_on_event_id }
      t.references :decidim_meeting_registration, foreign_key: { to_table: :decidim_meetings_registrations }, index: { name: "index_civicrm_event_meeting_registration_unique" }

      t.integer :civicrm_event_registration_id, null: false
      t.jsonb :extra, default: {}
      t.jsonb :data

      t.boolean :marked_for_deletion, default: false, null: false

      t.timestamps
    end
  end
end

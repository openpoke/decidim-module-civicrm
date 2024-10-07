# frozen_string_literal: true

class CreateDecidimCivicrmEventMeetings < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_civicrm_event_meetings do |t|
      t.references :decidim_meeting, null: false, index: { unique: true, name: "index_civicrm_event_meetings_unique" }
      t.references :decidim_organization, null: false, index: { name: "index_civicrm_event_meetings_organization" }
      t.integer :civicrm_registrations_count, default: 0

      t.integer :civicrm_event_id
      t.jsonb :extra, default: {}
      t.jsonb :data

      t.boolean :marked_for_deletion, default: false, null: false

      t.boolean :redirect_active, null: false, default: false
      t.string :redirect_url

      t.timestamps
    end
  end
end

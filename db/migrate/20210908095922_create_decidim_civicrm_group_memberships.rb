# frozen_string_literal: true

class CreateDecidimCivicrmGroupMemberships < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_civicrm_group_memberships do |t|
      t.references :group, null: false, foreign_key: { to_table: :decidim_civicrm_groups }, index: { name: :index_decidim_civicrm_group_memberships_on_group_id }
      t.references :contact, foreign_key: { to_table: :decidim_civicrm_contacts }, index: { name: :index_decidim_civicrm_group_memberships_on_contact_id }
      t.integer :civicrm_contact_id, index: true
      t.boolean :marked_for_deletion, default: false, null: false
      t.jsonb :extra, default: {}

      t.timestamps

      t.index %w(civicrm_contact_id group_id), name: "index_unique_civicrm_membership_group_and_contact", unique: true
    end
  end
end

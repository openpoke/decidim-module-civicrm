# frozen_string_literal: true

class CreateDecidimCivicrmGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_civicrm_groups do |t|
      t.references :decidim_organization, null: false, foreign_key: { to_table: :decidim_organizations }, index: { name: :index_decidim_civicrm_groups_on_decidim_organization_id }

      t.integer :civicrm_group_id, null: false
      t.integer :civicrm_member_count, default: 0

      t.string :title
      t.string :description
      t.jsonb :extra, default: {}

      t.boolean :marked_for_deletion, default: false, null: false
      t.boolean :auto_sync_members, default: false, null: false

      t.index %w(decidim_organization_id civicrm_group_id), name: "index_unique_civicrm_group_and_organization", unique: true
      t.timestamps
    end
  end
end

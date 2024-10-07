# frozen_string_literal: true

class CreateDecidimCivicrmContacts < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_civicrm_contacts do |t|
      t.references :decidim_organization, null: false, foreign_key: { to_table: :decidim_organizations }, index: { name: :index_civicrm_contacts_on_decidim_organization_id }
      t.references :decidim_user, null: false, foreign_key: { to_table: :decidim_users }, index: { name: :index_civicrm_contacts_on_decidim_user_id }

      t.integer :civicrm_contact_id, null: false
      t.integer :civicrm_uid
      t.jsonb :extra, default: {}

      t.boolean :marked_for_deletion, default: false, null: false

      t.timestamps

      t.index %w(decidim_organization_id civicrm_contact_id), name: "index_unique_civicrm_contact_and_organization", unique: true
    end
  end
end

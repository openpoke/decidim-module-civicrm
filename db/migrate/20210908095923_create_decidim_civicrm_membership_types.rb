# frozen_string_literal: true

class CreateDecidimCivicrmMembershipTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_civicrm_membership_types do |t|
      t.references :decidim_organization, foreign_key: { to_table: :decidim_organizations }, index: { name: :index_decidim_civicrm_membership_types_on_organization }

      t.integer :civicrm_membership_type_id, null: false
      t.string :name, null: false

      t.boolean :marked_for_deletion, default: false, null: false

      t.timestamps
    end
  end
end

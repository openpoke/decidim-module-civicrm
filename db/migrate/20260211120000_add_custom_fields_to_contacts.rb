# frozen_string_literal: true

class AddCustomFieldsToContacts < ActiveRecord::Migration[6.0]
  def change
    add_column :decidim_civicrm_contacts, :custom_fields, :jsonb, default: {}
    add_column :decidim_civicrm_group_memberships, :custom_fields, :jsonb, default: {}
  end
end

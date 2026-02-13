# frozen_string_literal: true

namespace :civicrm do
  # invoke with 'bundle exec rake "civicrm:sync:groups"'

  namespace :sync do
    desc "Sync Civicrm Groups and all related memberships with CiViCRM API"
    task groups: :environment do
      Decidim::Organization.find_each do |organization|
        Decidim::Civicrm::SyncAllGroupsJob.perform_now(organization.id)
      end
    end

    desc "Synchronize data between group memberships that share the same civicrm_contact_id"
    task duplicate_memberships: :environment do
      Decidim::Civicrm::SyncDuplicateGroupMembershipsJob.perform_now
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

# We make sure that the checksum of the file overriden is the same
# as the expected. If this test fails, it means that the overriden
# file should be updated to match any change/bug fix introduced in the core
checksums = [
  {
    package: "decidim-core",
    files: {
      "/app/commands/decidim/create_omniauth_registration.rb" => "10fc028fa6a7bef9936e6f9edb9b167b",
      "/app/commands/decidim/update_account.rb" => "012e0dcd584135fa70ba6bd323540f7c"
    }
  },
  {
    package: "decidim-admin",
    files: {
      "/app/controllers/decidim/admin/resource_permissions_controller.rb" => "ef48d0cd3a04fb9783f84bb7f61893d3"
    }
  },
  {
    package: "decidim-meetings",
    files: {
      "/app/controllers/decidim/meetings/registrations_controller.rb" => "77274bb241d55cd570f563f967843a72",
      "/app/commands/decidim/meetings/join_meeting.rb" => "3c0477dc5ba6f164e78f4b06a320a4ed"
    }
  }
]

describe "Overriden files", type: :view do
  checksums.each do |item|
    # rubocop:disable Rails/DynamicFindBy
    spec = ::Gem::Specification.find_by_name(item[:package])
    # rubocop:enable Rails/DynamicFindBy
    item[:files].each do |file, signature|
      it "#{spec.gem_dir}#{file} matches checksum" do
        expect(md5("#{spec.gem_dir}#{file}")).to eq(signature)
      end
    end
  end

  private

  def md5(file)
    Digest::MD5.hexdigest(File.read(file))
  end
end

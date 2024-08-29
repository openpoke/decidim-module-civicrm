# frozen_string_literal: true

require "spec_helper"

# We make sure that the checksum of the file overriden is the same
# as the expected. If this test fails, it means that the overriden
# file should be updated to match any change/bug fix introduced in the core
checksums = [
  {
    package: "decidim-core",
    files: {
      "/app/commands/decidim/create_omniauth_registration.rb" => "586139f98ded0645eb83e480ef5dd6bd",
      "/app/commands/decidim/update_account.rb" => "29d81617f5bf1af310d2777a916b4d8b"
    }
  },
  {
    package: "decidim-admin",
    files: {
      "/app/controllers/decidim/admin/resource_permissions_controller.rb" => "f3a204b0f85cc18556aadaa26ee68dc7"
    }
  },
  {
    package: "decidim-meetings",
    files: {
      "/app/controllers/decidim/meetings/registrations_controller.rb" => "77274bb241d55cd570f563f967843a72",
      "/app/commands/decidim/meetings/join_meeting.rb" => "58c65f8451ab82639249ea8401838ab0"
    }
  }
]

describe "Overriden files", type: :view do
  checksums.each do |item|
    spec = Gem::Specification.find_by_name(item[:package])
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

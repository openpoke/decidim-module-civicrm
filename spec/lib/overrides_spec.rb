# frozen_string_literal: true

require "spec_helper"

# We make sure that the checksum of the file overriden is the same
# as the expected. If this test fails, it means that the overriden
# file should be updated to match any change/bug fix introduced in the core
checksums = [
  {
    package: "decidim-core",
    files: {
      "/app/commands/decidim/update_account.rb" => "2c4f0e5a693b4b46a8e39e12dd9ecb2a",
      "/app/controllers/decidim/devise/omniauth_registrations_controller.rb" => "cafb652eb07048c88a4c233e4fce77d5"
    }
  },
  {
    package: "decidim-admin",
    files: {
      "/app/controllers/decidim/admin/resource_permissions_controller.rb" => "74b7178ed312972791bda409ab01b3a4"
    }
  },
  {
    package: "decidim-meetings",
    files: {
      "/app/controllers/decidim/meetings/registrations_controller.rb" => "cdd2054a45e90088f867b52bbd49e626",
      "/app/commands/decidim/meetings/join_meeting.rb" => "a16c129d870df19bf4b3fadffb88d738"
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

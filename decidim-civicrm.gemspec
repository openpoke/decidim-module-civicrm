# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/civicrm/version"

Gem::Specification.new do |s|
  s.version = Decidim::Civicrm::DECIDIM_VERSION
  s.authors = ["Ivan Vergés", "Vera Rojman"]
  s.email = ["ivan@pokecode.net"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/openpoke/decidim-module-decidim_civicrm"
  s.required_ruby_version = ">= 2.7"

  s.name = "decidim-civicrm"
  s.summary = "A Decidim module to connect with CiViCRM as OAUTH provider and perform verifications based on CiViCRM Contact attributes."
  s.description = "A Decidim module to connect with CiViCRM as OAUTH provider and perform verifications based on CiViCRM Contact attributes."

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE-AGPLv3.txt", "Rakefile", "package.json", "README.md"]

  s.require_paths = ["lib"]

  s.add_dependency "decidim-admin", Decidim::Civicrm::COMPAT_DECIDIM_VERSION
  s.add_dependency "decidim-core", Decidim::Civicrm::COMPAT_DECIDIM_VERSION
  s.add_dependency "decidim-verifications", Decidim::Civicrm::COMPAT_DECIDIM_VERSION
  s.add_dependency "deface", "~> 1.5"

  s.add_development_dependency "decidim-dev", Decidim::Civicrm::COMPAT_DECIDIM_VERSION
end

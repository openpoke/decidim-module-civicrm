# frozen_string_literal: true

require "decidim/core/test/factories"
require "decidim/meetings/test/factories"

FactoryBot.define do
  factory :civicrm_contact, class: "Decidim::Civicrm::Contact" do
    user
    organization
    sequence(:civicrm_contact_id)
    extra do
      {
        extra_attribute: "123"
      }
    end
  end

  factory :civicrm_group, class: "Decidim::Civicrm::Group" do
    organization
    sequence(:civicrm_group_id)
    title { Faker::Lorem.sentence(word_count: 2) }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    extra do
      {
        extra_attribute: "123"
      }
    end
  end

  factory :civicrm_group_membership, class: "Decidim::Civicrm::GroupMembership" do
    group factory: :civicrm_group
    contact factory: :civicrm_contact
    sequence(:civicrm_contact_id)
    extra do
      {
        display_name: Faker::Name.name,
        email: Faker::Internet.email
      }
    end
  end

  factory :civicrm_group_participatory_space, class: "Decidim::Civicrm::GroupParticipatorySpace" do
    group factory: :civicrm_group
    association :participatory_space, factory: :participatory_process
  end

  factory :civicrm_event_meeting, class: "Decidim::Civicrm::EventMeeting" do
    organization
    meeting factory: :meeting
    redirect_url { Faker::Internet.url }
    redirect_active { true }
    sequence(:civicrm_event_id)

    trait :minimal do
      meeting { nil }
      redirect_url { nil }
      redirect_active { false }
    end
  end

  factory :civicrm_event_registration, class: "Decidim::Civicrm::EventRegistration" do
    event_meeting factory: :civicrm_event_meeting
    meeting_registration factory: :registration
    sequence(:civicrm_event_registration_id)
  end

  factory :civicrm_membership_type, class: "Decidim::Civicrm::MembershipType" do
    organization
    sequence(:civicrm_membership_type_id)
    name { Faker::Lorem.word }
  end
end

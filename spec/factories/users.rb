# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    association :organization, factory: :organization, strategy: :build

    trait :admin do
      email { 'team@localviking.com' }
    end
  end
end

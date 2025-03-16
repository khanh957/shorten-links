FactoryBot.define do
  factory :short_url do
    original_url { "https://example.com" }
    short_code { SecureRandom.alphanumeric(6) }
    expired_at { nil }

    trait :expired do
      expired_at { 1.hour.ago }
    end
  end
end

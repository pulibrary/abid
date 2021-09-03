# frozen_string_literal: true
FactoryBot.define do
  factory :marc_batch do
    user
    prefix { "N" }
    factory :synchronized_marc_batch do
      after(:create) do |batch, _|
        create(:marc_absolute_identifier, sync_status: "synchronized", batch: batch)
      end
    end
    factory :unsynchronized_marc_batch do
      after(:create) do |batch, _|
        create(:marc_absolute_identifier, sync_status: "unsynchronized", batch: batch)
      end
    end
  end
end

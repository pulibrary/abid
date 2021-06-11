# frozen_string_literal: true

FactoryBot.define do
  factory :batch do
    start_box { 31 }
    end_box { 31 }
    first_barcode { "32101113344905" }
    call_number { "ABID001" }
    location_uri { "/locations/23648" } # mss
    # "Standard manuscript", S for mudd and B for firestone.
    container_profile_uri { "/container_profiles/18" }
    user
    # resource_uri { "/repositories/4/resources/4188" }
    factory :mudd_batch do
      location_uri { "/locations/23649" } # mudd
    end
    factory :synchronized_batch do
      after(:create) do |batch, _|
        batch.absolute_identifiers.update(sync_status: "synchronized")
      end
    end
  end
end

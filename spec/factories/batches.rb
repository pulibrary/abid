# frozen_string_literal: true

FactoryBot.define do
  factory :batch do
    start_box { 1 }
    end_box { 1 }
    first_barcode { "MyString" }
    call_number { "ABID001" }
    location_uri { "MyString" }
    container_profile_uri { "MyString" }
    # resource_uri { "/repositories/4/resources/4188" }
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :batch do
    start_box { 1 }
    end_box { 1 }
    first_barcode { "MyString" }
    call_number { "MyString" }
    location_uri { "MyString" }
    container_profile_uri { "MyString" }
  end
end

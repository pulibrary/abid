# frozen_string_literal: true
FactoryBot.define do
  factory :absolute_identifier do
    original_box_number { 1 }
    top_container_uri { "MyString" }
    batch_id { 1 }
    prefix { "MyString" }
    suffix { "MyString" }
    sync_status { "MyString" }
    pool_identifier { "MyString" }
  end
end

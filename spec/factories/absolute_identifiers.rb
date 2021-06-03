# frozen_string_literal: true
FactoryBot.define do
  factory :absolute_identifier do
    original_box_number { 1 }
    # This is box 31 in ABID001
    top_container_uri { "/repositories/4/top_containers/118271" }
    prefix { "S" }
    suffix { 1 }
    sync_status { "unsynchronized" }
    pool_identifier { "firestone" }
    batch
  end
end

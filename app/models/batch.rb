# frozen_string_literal: true

# == Schema Information
#
# Table name: batches
#
#  id                    :bigint           not null, primary key
#  call_number           :string
#  container_profile_uri :string
#  end_box               :integer
#  first_barcode         :string
#  location_uri          :string
#  resource_uri          :string
#  start_box             :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
class Batch < ApplicationRecord
  validates :call_number, :container_profile_uri, :start_box, :end_box, presence: true
  validates :end_box, numericality: { allow_nil: true, greater_than_or_equal_to: ->(batch) { batch.start_box.to_i } }
end

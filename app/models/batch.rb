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
#  start_box             :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
class Batch < ApplicationRecord
end

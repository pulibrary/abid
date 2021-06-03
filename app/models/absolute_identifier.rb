# frozen_string_literal: true

# == Schema Information
#
# Table name: absolute_identifiers
#
#  id                  :bigint           not null, primary key
#  original_box_number :integer
#  pool_identifier     :string
#  prefix              :string
#  suffix              :string
#  sync_status         :string
#  top_container_uri   :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  batch_id            :integer
#
class AbsoluteIdentifier < ApplicationRecord
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: absolute_identifiers
#
#  id                  :bigint           not null, primary key
#  original_box_number :integer
#  pool_identifier     :string
#  prefix              :string
#  suffix              :integer
#  sync_status         :string
#  top_container_uri   :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  batch_id            :integer
#
class AbsoluteIdentifier < ApplicationRecord
  validates :sync_status, :pool_identifier, :suffix, :original_box_number, :prefix, :top_container_uri, presence: true
  belongs_to :batch
  attribute :sync_status, :string, default: "unsynchronized"

  def full_identifier
    format("#{prefix}-%.6d", suffix)
  end
end

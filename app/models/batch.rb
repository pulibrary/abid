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
  validate :call_number_exists_in_aspace

  def call_number_exists_in_aspace
    # Use resource_uri as a cache of its path.
    # @note This falls apart if we need to handle the EAD maybe getting deleted,
    # but that should be rare.
    return if resource_uri.present?
    resource_uri = aspace_client.find_resource_uri(ead_id: call_number)
    if resource_uri.blank?
      errors.add(:call_number, "does not exist in ArchivesSpace")
    else
      self.resource_uri = resource_uri
    end
  end

  def aspace_client
    @aspace_client ||= Aspace::Client.new
  end
end

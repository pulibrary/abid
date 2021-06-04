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
#  user_id               :bigint
#
# Indexes
#
#  index_batches_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Batch < ApplicationRecord
  validates :first_barcode, :call_number, :container_profile_uri, :location_uri, :start_box, :end_box, presence: true
  validates :end_box, numericality: { allow_nil: true, greater_than_or_equal_to: ->(batch) { batch.start_box.to_i } }
  validate :call_number_exists_in_aspace
  validate :top_containers_exist_in_aspace
  has_many :absolute_identifiers, dependent: :destroy
  belongs_to :user

  before_save :create_absolute_identifiers

  def location
    @location ||= aspace_client.get_location(ref: location_uri)
  end

  def container_profile
    @container_profile = aspace_client.get_container_profile(ref: container_profile_uri)
  end

  private

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

  def top_containers_exist_in_aspace
    return unless resource_uri.present? && start_box.present? && end_box.present? && end_box >= start_box
    if top_containers.length < (start_box..end_box).size
      errors.add(:base, "Unable to find matching top containers for all boxes in #{start_box} - #{end_box}")
    end
  end

  def create_absolute_identifiers
    return unless absolute_identifiers.empty?
    top_containers.each_with_index do |top_container, idx|
      absolute_identifier = AbsoluteIdentifier.new(
        barcode: barcodes[idx],
        original_box_number: top_container.indicator,
        pool_identifier: pool_identifier,
        prefix: abid_prefix,
        top_container_uri: top_container.uri
      )
      absolute_identifiers << absolute_identifier
    end
  end

  def pool_identifier
    location.pool_identifier
  end

  def abid_prefix
    @abid_prefix ||= container_profile.abid_prefix(pool_identifier: pool_identifier)
  end

  def top_containers
    @top_containers ||= aspace_client.find_top_containers(repository_uri: repository_uri, ead_id: call_number, indicators: start_box..end_box).sort_by(&:indicator)
  end

  def barcodes
    @barcodes ||=
      begin
        barcode = BarcodeService.new(first_barcode)
        new_barcodes = barcode.next(count: top_containers.length - 1)
        [barcode.barcode] + new_barcodes
      end
  end

  def repository_uri
    return if resource_uri.blank?
    resource_uri.to_s.split("/")[0..2].join("/")
  end

  def aspace_client
    @aspace_client ||= Aspace::Client.new
  end
end

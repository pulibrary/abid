# frozen_string_literal: true

# == Schema Information
#
# Table name: batches
#
#  id                     :bigint           not null, primary key
#  call_number            :string
#  container_profile_data :jsonb
#  container_profile_uri  :string
#  end_box                :integer
#  first_barcode          :string
#  generate_abid          :boolean          default(TRUE)
#  location_data          :jsonb
#  location_uri           :string
#  resource_uri           :string
#  start_box              :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  user_id                :bigint
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
  validate :first_barcode_valid
  validate :barcodes_not_taken
  validate :barcodes_not_in_aspace
  has_many :absolute_identifiers, dependent: :destroy
  belongs_to :user

  before_save :cache_location_data
  before_save :cache_container_profile_data
  after_save :create_absolute_identifiers

  def location
    @location ||=
      begin
        if location_data
          Location.new(location_data)
        else
          aspace_client.get_location(ref: location_uri)
        end
      end
  end

  def cache_location_data
    self.location_data = location.source
  end

  def cache_container_profile_data
    self.container_profile_data = container_profile.source
  end

  def container_profile
    @container_profile =
      begin
        if container_profile_data
          ContainerProfile.new(container_profile_data)
        else
          aspace_client.get_container_profile(ref: container_profile_uri)
        end
      end
  end

  def synchronized?
    absolute_identifiers.synchronized.size == absolute_identifiers.size
  end

  def synchronize
    absolute_identifiers.each(&:synchronize)
  end

  def to_csv
    CSV.generate(headers: true) do |csv|
      csv << csv_attributes(absolute_identifiers.first).keys

      absolute_identifiers.each do |record|
        csv << csv_attributes(record)
      end
    end
  end

  def barcodes
    @barcodes ||=
      begin
        barcode = BarcodeService.new(first_barcode)
        new_barcodes = barcode.next(count: top_containers.length - 1)
        [barcode.barcode] + new_barcodes
      end
  end

  private

  def first_barcode_valid
    return true if BarcodeService.valid?(first_barcode)
    errors.add(:first_barcode, "is not valid")
  end

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

  def barcodes_not_taken
    return unless ready_for_aspace_checks?
    unless AbsoluteIdentifier.where(barcode: barcodes).empty?
      errors.add(:base, "One of the generated barcodes is already attached to an item in the system.")
    end
  end

  def barcodes_not_in_aspace
    return unless ready_for_aspace_checks?
    matches = aspace_client.find_barcodes(barcodes: barcodes)
    if matches.present?
      errors.add(:base, "One of the generated barcodes are already in ArchivesSpace.")
    end
  end

  def top_containers_exist_in_aspace
    return unless ready_for_aspace_checks?
    if top_containers.length < (start_box..end_box).size
      errors.add(:base, "Unable to find matching top containers for all boxes in #{start_box} - #{end_box}")
    end
  end

  def ready_for_aspace_checks?
    resource_uri.present? && start_box.present? && end_box.present? && end_box >= start_box
  end

  # Create an AbID for every top container. Manually increment the suffix after
  # the first one because, as the transaction hasn't closed, each subsequent
  # AbID can not query the database for what the most recent one is.
  def create_absolute_identifiers
    return unless absolute_identifiers.empty?
    suffix = nil
    top_containers.each_with_index do |top_container, idx|
      abid = AbsoluteIdentifier.create!(
        barcode: barcodes[idx],
        original_box_number: top_container.indicator,
        pool_identifier: pool_identifier,
        prefix: abid_prefix,
        top_container_uri: top_container.uri,
        suffix: suffix,
        batch: self
      )
      # If the first abid didn't generate a suffix, it means it isn't supposed
      # to - probaably because the batch is set to not generate AbIDs.
      suffix = abid.suffix + 1 if abid.suffix
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

  def repository_uri
    return if resource_uri.blank?
    resource_uri.to_s.split("/")[0..2].join("/")
  end

  def aspace_client
    @aspace_client ||= Aspace::Client.new
  end

  def csv_attributes(record)
    {
      id: record.id,
      abid: record.full_identifier,
      box_number: record.original_box_number,
      user: user.uid,
      barcode: record.barcode,
      location: location.title,
      container_profile: container_profile_data["name"],
      call_number: call_number,
      status: record.sync_status
    }
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: absolute_identifiers
#
#  id                  :bigint           not null, primary key
#  barcode             :string
#  batch_type          :string           default("Batch")
#  holding_cache       :jsonb
#  original_box_number :integer
#  pool_identifier     :string
#  prefix              :string
#  suffix              :integer
#  sync_status         :string
#  top_container_uri   :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  batch_id            :bigint
#  holding_id          :string
#
# Indexes
#
#  absolute_identifiers_uniqueness         (prefix,suffix,pool_identifier) UNIQUE
#  index_absolute_identifiers_on_batch_id  (batch_id)
#
class AbsoluteIdentifier < ApplicationRecord
  validates :sync_status, :pool_identifier, :prefix, :barcode, presence: true
  belongs_to :batch, polymorphic: true
  attribute :sync_status, :string, default: "unsynchronized"
  before_save :set_suffix
  before_save :cache_holding_id
  scope :synchronized, -> { where(sync_status: "synchronized") }
  validate :barcode_in_alma
  validate :barcode_in_special_collections
  validate :holding_id_unique

  def full_identifier
    return if suffix.blank?
    format("#{prefix}-%.6d", suffix)
  end

  def set_suffix
    return if suffix.present? || !generate_abid
    self.suffix = highest_identifier + 1
  end

  def synchronize
    Synchronizer.for(absolute_identifier: self).sync!
  end

  def generate_abid
    if batch
      batch.generate_abid
    else
      true
    end
  end

  def alma_item
    @alma_item ||=
      begin
        return Alma::BibItem.new(holding_cache) if holding_cache.present?
        item = Alma::BibItem.find_by_barcode(barcode)
        if item.item.dig("errorList", "error", 0, "errorCode").blank?
          item
        end
      end
  end

  def previous_call_number
    return if holding_cache.blank?
    alma_item.holding_data["permanent_call_number"]
  end

  def cache_holding_id
    return if holding_id.present? || !batch.is_a?(MarcBatch) || alma_item.blank?
    self.holding_cache = alma_item.item
    self.holding_id = alma_item["holding_data"]["holding_id"]
  end

  # Get all AbIDs which are for this AbID's holding, but with a different
  # prefix.
  def different_size_holding_abids
    return [] unless batch.is_a?(MarcBatch)
    cache_holding_id
    self.class.where(holding_id: holding_id).where.not(prefix: prefix)
  end

  private

  def highest_identifier
    self.class.where(prefix: prefix, pool_identifier: pool_identifier).where.not(suffix: nil).order(suffix: :desc).pick(:suffix) || last_legacy_identifier
  end

  # The old database ended identifiers for each pool at certain numbers - ensure
  # we start from those numbers.
  def last_legacy_identifier
    legacy_identifiers.dig(pool_identifier, prefix) || 0
  end

  def legacy_identifiers
    {
      "firestone" => {
        "S" => 250,
        "Z" => 34,
        "Q" => 1027,
        "P" => 161,
        "N" => 2632,
        "L" => 29,
        "F" => 186,
        "E" => 114,
        "B" => 1568
      }
    }
  end

  def barcode_in_alma
    return unless batch.is_a?(MarcBatch)
    return if alma_item.present?
    errors.add(:barcode, "is not present in Alma")
  end

  def barcode_in_special_collections
    return unless batch.is_a?(MarcBatch)
    return if alma_item&.library == "rare"
    errors.add(:barcode, "is for an item not in the 'rare' library.")
  end

  def holding_id_unique
    return unless batch.is_a?(MarcBatch)
    return if batch.ignore_size_validation
    existing_abids = different_size_holding_abids
    return if existing_abids.blank?
    errors.add(:barcode, "an AbID with this holding ID but a different prefix (#{existing_abids.first.prefix}) exists.")
  end
end

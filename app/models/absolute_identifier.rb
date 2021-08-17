# frozen_string_literal: true

# == Schema Information
#
# Table name: absolute_identifiers
#
#  id                  :bigint           not null, primary key
#  barcode             :string
#  batch_type          :string           default("Batch")
#  original_box_number :integer
#  pool_identifier     :string
#  prefix              :string
#  suffix              :integer
#  sync_status         :string
#  top_container_uri   :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  batch_id            :bigint
#
# Indexes
#
#  absolute_identifiers_uniqueness         (prefix,suffix,pool_identifier) UNIQUE
#  index_absolute_identifiers_on_batch_id  (batch_id)
#
class AbsoluteIdentifier < ApplicationRecord
  validates :sync_status, :pool_identifier, :original_box_number, :prefix, :top_container_uri, :barcode, presence: true
  belongs_to :batch, polymorphic: true
  attribute :sync_status, :string, default: "unsynchronized"
  before_save :set_suffix
  scope :synchronized, -> { where(sync_status: "synchronized") }

  def full_identifier
    return if suffix.blank?
    format("#{prefix}-%.6d", suffix)
  end

  def set_suffix
    return if suffix.present? || !generate_abid
    self.suffix = highest_identifier + 1
  end

  def synchronize
    Synchronizer.new(absolute_identifier: self).sync!
  end

  def generate_abid
    if batch
      batch.generate_abid
    else
      true
    end
  end

  private

  def highest_identifier
    self.class.where(prefix: prefix, pool_identifier: pool_identifier).order(suffix: :desc).pick(:suffix) || last_legacy_identifier
  end

  # The old database ended identifiers for each pool at certain numbers - ensure
  # we start from those numbers.
  def last_legacy_identifier
    legacy_identifiers.dig(pool_identifier, prefix) || 0
  end

  def legacy_identifiers
    {
      "firestone" => {
        "S" => 247,
        "Z" => 34,
        "Q" => 1019,
        "P" => 161,
        "N" => 2621,
        "L" => 29,
        "F" => 185,
        "E" => 114,
        "B" => 1568
      }
    }
  end
end

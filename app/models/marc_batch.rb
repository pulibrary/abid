# frozen_string_literal: true

# == Schema Information
#
# Table name: marc_batches
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_marc_batches_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class MarcBatch < ApplicationRecord
  has_many :absolute_identifiers, dependent: :destroy, as: :batch
  belongs_to :user
  accepts_nested_attributes_for :absolute_identifiers, reject_if: proc { |attributes| attributes["barcode"].blank? }
  validate :abids_unique_holding_ids

  def generate_abid
    true
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

  def csv_attributes(record)
    {
      id: record.id,
      abid: record.full_identifier,
      box_number: record.original_box_number,
      user: user.uid,
      barcode: record.barcode,
      location: nil,
      container_profile: nil,
      call_number: nil,
      status: record.sync_status
    }
  end

  private

  def abids_unique_holding_ids
    absolute_identifiers.each(&:cache_holding_id)
    absolute_identifiers.group_by(&:holding_id).each do |_holding_id, group|
      next unless group.map(&:prefix).uniq.length != 1
      barcodes = group.map(&:barcode)
      group.each do |absolute_identifier|
        absolute_identifier.errors.add(:prefix, "has the same holding ID but different prefix as #{barcodes.excluding(absolute_identifier.barcode).to_sentence}.")
      end
      errors.add(:base, "Issue with barcodes #{barcodes.to_sentence}")
    end
  end
end

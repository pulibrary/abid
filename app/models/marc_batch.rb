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
  accepts_nested_attributes_for :absolute_identifiers

  def generate_abid
    true
  end

  def synchronized?
    absolute_identifiers.synchronized.size == absolute_identifiers.size
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
end

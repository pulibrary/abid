# frozen_string_literal: true

# == Schema Information
#
# Table name: absolute_identifiers
#
#  id                  :bigint           not null, primary key
#  barcode             :string
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
#  index_absolute_identifiers_on_batch_id  (batch_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#
class AbsoluteIdentifier < ApplicationRecord
  validates :sync_status, :pool_identifier, :original_box_number, :prefix, :top_container_uri, :barcode, presence: true
  belongs_to :batch
  attribute :sync_status, :string, default: "unsynchronized"
  before_save :set_suffix

  def full_identifier
    format("#{prefix}-%.6d", suffix)
  end

  def set_suffix
    return if suffix.present?
    self.suffix = highest_identifier + 1
  end

  def synchronize
    Synchronizer.new(absolute_identifier: self).sync!
  end

  private

  def highest_identifier
    self.class.where(prefix: prefix, pool_identifier: pool_identifier).order(suffix: :desc).pick(:suffix) || 0
  end
end

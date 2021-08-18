# frozen_string_literal: true

# == Schema Information
#
# Table name: marc_batches
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class MarcBatch < ApplicationRecord
  has_many :absolute_identifiers, dependent: :destroy, as: :batch
  accepts_nested_attributes_for :absolute_identifiers

  def generate_abid
    true
  end
end

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
end

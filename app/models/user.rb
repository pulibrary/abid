# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                  :bigint           not null, primary key
#  provider            :string           default("cas"), not null
#  remember_created_at :datetime
#  uid                 :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_users_on_provider          (provider)
#  index_users_on_uid               (uid) UNIQUE
#  index_users_on_uid_and_provider  (uid,provider) UNIQUE
#
class User < ApplicationRecord
  # Include default devise modules
  devise :rememberable, :omniauthable
  has_many :batches, -> { order(created_at: :desc) }, dependent: :destroy

  def self.from_cas(access_token)
    User.find_by(provider: access_token.provider, uid: access_token.uid)
  end

  def synchronized_batches
    batches.select(&:synchronized?)
  end

  def unsynchronized_batches
    batches.reject(&:synchronized?)
  end
end

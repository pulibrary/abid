# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                  :bigint           not null, primary key
#  aspace_uri          :string
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
  has_many :marc_batches, -> { order(created_at: :desc) }, dependent: :destroy

  def self.from_cas(access_token)
    user = User.find_by(provider: access_token.provider, uid: access_token.uid)
    user_with_aspace_uri(user) || create_user_from_aspace(access_token)
  end

  def self.create_user_from_aspace(access_token)
    aspace_user = Aspace::Client.new.find_aspace_user(access_token.uid)
    return if aspace_user.blank?
    User.create(provider: access_token.provider, uid: access_token.uid, aspace_uri: aspace_user["uri"])
  end

  def self.user_with_aspace_uri(user)
    if user && user.aspace_uri.blank?
      aspace_user = Aspace::Client.new.find_aspace_user(user.uid)
      user.update(aspace_uri: aspace_user&.fetch("uri", nil))
    end
    user
  end

  def authorized?
    if aspace_uri.present?
      aspace_info = Aspace::Client.new.user_info(ref: aspace_uri)
      aspace_info["is_admin"] || aspace_info["permissions"].values.inject(:+).present?
    else
      false
    end
  rescue => e
    Rails.logger.error e
    false
  end

  def synchronized_batches
    (batches.select(&:synchronized?) + marc_batches.select(&:synchronized?)).sort_by(&:created_at)
  end

  def unsynchronized_batches
    (batches.reject(&:synchronized?) + marc_batches.reject(&:synchronized?)).sort_by(&:created_at)
  end
end

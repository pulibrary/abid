# frozen_string_literal: true

require "application_record"
require "aspace/client"

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
  #
  # `devise :rememberable, :omniauthable` is gone with Devise itself; the CAS
  # request phase is Rack middleware now and nothing else here depended on it.
  #
  # `class_name:` is stated explicitly because ApplicationRecord singularises
  # association names with a plain /s\z/ strip ("batches" -> "Batche").
  # The scope lambdas take the relation as an argument, which is how
  # ApplicationRecord calls them.
  has_many :batches, ->(scope) { scope.order(created_at: :desc) }, dependent: :destroy, class_name: "Batch"
  has_many :marc_batches, ->(scope) { scope.order(created_at: :desc) }, dependent: :destroy, class_name: "MarcBatch"

  def self.from_cas(access_token)
    user = User.find_by(provider: access_token.provider, uid: access_token.uid)
    user_with_aspace_uri(user) || create_user_from_aspace(access_token)
  end

  def self.create_user_from_aspace(access_token)
    aspace_user = Aspace::Client.new.find_aspace_user(access_token.uid)
    return if blank_value?(aspace_user)
    User.create(provider: access_token.provider, uid: access_token.uid, aspace_uri: aspace_user["uri"])
  end

  def self.user_with_aspace_uri(user)
    if user && blank_value?(user.aspace_uri)
      aspace_user = Aspace::Client.new.find_aspace_user(user.uid)
      user.update(aspace_uri: aspace_user&.fetch("uri", nil))
    end
    user
  end

  def authorized?
    if !value_blank?(aspace_uri)
      aspace_info = Aspace::Client.new.user_info(ref: aspace_uri)
      aspace_info["is_admin"] || !value_blank?(aspace_info["permissions"].values.inject(:+))
    else
      false
    end
  end

  def synchronized_batches
    (batches.select(&:synchronized?) + marc_batches.select(&:synchronized?)).sort_by(&:created_at)
  end

  def unsynchronized_batches
    (batches.reject(&:synchronized?) + marc_batches.reject(&:synchronized?)).sort_by(&:created_at)
  end

  # ActiveSupport's Object#blank?, which this port may not use. Identical to
  # ApplicationRecord#value_blank?, restated here because the two callers above
  # are class methods and that one is a private instance method.
  def self.blank_value?(value)
    case value
    when nil, false then true
    when String then value.strip.empty?
    when Array, Hash then value.empty?
    else value.respond_to?(:empty?) ? value.empty? : false
    end
  end
  private_class_method :blank_value?
end

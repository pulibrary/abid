class User < ApplicationRecord
  # Include default devise modules
  devise :rememberable, :omniauthable

  def self.from_cas(access_token)
    User.find_by(provider: access_token.provider, uid: access_token.uid)
  end
end

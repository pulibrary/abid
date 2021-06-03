# frozen_string_literal: true
namespace :users do
  desc "Populate users from list of netids"
  task populate: :environment do
    abort 'usage: rake users:populate NETIDS="netid1 netid2"' unless ENV["NETIDS"]
    netids = ENV["NETIDS"].split(" ")
    netids.each do |netid|
      User.find_or_create_by(uid: netid)
    end
  end
end

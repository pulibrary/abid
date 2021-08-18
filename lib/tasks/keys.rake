# frozen_string_literal: true
desc "Installs ASpace access key into .env via lastpass."
task setup_keys: :environment do
  content = JSON.parse(`lpass show Shared-ITIMS-Passwords/pulfa/aspace.princeton.edu -j`).first
  alma_key = JSON.parse(JSON.parse(`lpass show Shared-ITIMS-Passwords/alma/AbID-Alma-Keys -j`).first["note"])["sandbox"]
  File.open(".env", "w") do |f|
    f.puts "ASPACE_URL=https://aspace-staging.princeton.edu/staff/api"
    f.puts "ASPACE_USER=#{content['username']}"
    f.puts "ASPACE_PASSWORD=#{content['password']}"
    f.puts "ALMA_API_KEY=#{alma_key}"
  end
  puts "Generated .env file"
end

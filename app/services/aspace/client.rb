# frozen_string_literal: true
module Aspace
  class Client < ArchivesSpace::Client
    def self.config
      ArchivesSpace::Configuration.new(
        {
          base_uri: Abid.config["archivespace_url"],
          username: Abid.config["archivespace_user"],
          password: Abid.config["archivespace_password"],
          page_size: 50,
          throttle: 0
        }
      )
    end

    def initialize
      super(self.class.config)
      login
    end
  end
end

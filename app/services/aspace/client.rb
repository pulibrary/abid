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

    def find_resource_uri(ead_id:)
      return if ead_id.blank?
      repositories.each do |repository|
        identifier_query = [ead_id]
        params = URI.encode_www_form([["identifier[]", identifier_query.to_json]])
        path = "#{repository['uri']}/find_by_id/resources?#{params}"
        uri = get(path)
        uri = uri.parsed["resources"].first&.fetch("ref", nil)
        return uri if uri.present?
      end
    end
  end
end

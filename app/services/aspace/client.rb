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

    def find_aspace_user(username)
      users.find do |user|
        user["username"] == username
      end
    end

    def user_info(ref:)
      get(ref).parsed
    end

    def find_top_containers(repository_uri:, ead_id:, indicators:)
      query_params = []
      query_params << ["q", "collection_identifier_u_stext:#{ead_id} indicator_u_icusort:[#{indicators.first} TO #{indicators.last}] type_enum_s:box"]

      query_params << ["type[]", "top_container"]
      query_params << ["fields[]", "uri"]
      query_params << ["fields[]", "indicator_u_icusort"]
      query_params << ["page", "1"]

      query = URI.encode_www_form(query_params)
      response = get("#{repository_uri}/search?#{query}")
      response.parsed.fetch("results", []).map do |result|
        TopContainer.new(result)
      end
    end

    def find_barcodes(barcodes:)
      query_params = []
      query_params << ["q", "barcode_u_icusort:(#{barcodes.join(' OR ')}) type_enum_s:box"]

      query_params << ["type[]", "top_container"]
      query_params << ["fields[]", "uri"]
      query_params << ["fields[]", "indicator_u_icusort"]
      query_params << ["fields[]", "barcode_u_icusort"]
      query_params << ["page", "1"]

      query = URI.encode_www_form(query_params)
      response = get("/search?#{query}")
      response.parsed.fetch("results", []).map do |result|
        TopContainer.new(result)
      end
    end

    def get_location(ref:)
      Location.new(get(ref).parsed)
    end

    def get_container_profile(ref:)
      ContainerProfile.new(get(ref).parsed)
    end

    def get_top_container(ref:)
      TopContainer.new(get(ref).parsed)
    end

    def locations
      locations = get("/locations?page=1&page_size=100").parsed["results"].map do |location|
        Location.new(location)
      end.sort_by(&:title)
      locations.select do |location|
        Location.configured_codes.include?(location.code)
      end
    end

    def container_profiles
      container_profiles = get("/container_profiles?page=1&page_size=100").parsed["results"].map do |container_profile|
        ContainerProfile.new(container_profile)
      end.sort_by(&:name)
      container_profiles.select(&:configured?)
    end

    def save_top_container(top_container:)
      output = post(top_container.uri, top_container.source.to_json)
      raise unless output.status.code == "200"
    end
  end
end

# frozen_string_literal: true

module AspaceStubbing
  def stub_aspace_login
    stub_request(:post, "https://aspace.test.org/staff/api/users/test/login?password=password").to_return(status: 200, body: { session: "1" }.to_json, headers: { "Content-Type": "application/json" })
  end

  def stub_repositories
    uri = "/repositories?page=1"
    path = Rails.root.join("spec", "fixtures", "aspace", "repositories_1.json")
    cache_path(uri: uri, path: path)
    stub_aspace_request(uri: uri, path: path)
  end

  def stub_top_container_search(ead_id:, repository_id:, indicators:)
    uri = "/repositories/#{repository_id}/search"
    uri += "?fields[]=uri&fields[]=indicator_u_icusort&page=1"
    uri += "&q=collection_identifier_u_stext:#{ead_id}%20indicator_u_icusort:%5B#{indicators.first}%20TO%20#{indicators.last}%5D&type%5B%5D=top_container"
    path = Rails.root.join("spec", "fixtures", "aspace", ead_id, "top_containers_#{indicators.first}_#{indicators.last}.json")
    cache_path(uri: uri, path: path)
    stub_aspace_request(uri: uri, path: path)
  end

  def stub_resource(ead_id: nil)
    stub_aspace_login
    stub_repositories
    repository_uris = Aspace::Client.new.repositories.map { |x| x["uri"] }
    repository_uris.each do |repository_uri|
      uri = "#{repository_uri}/find_by_id/resources?identifier[]=[\"#{ead_id}\"]"
      path = Rails.root.join("spec", "fixtures", "aspace", ead_id, "repository_#{repository_uri.split('/').last}_find_by.json")
      cache_path(uri: uri, path: path)
      stub_aspace_request(uri: uri, path: path)
    end
  end

  def stub_aspace_request(uri:, path:)
    stub_request(:get, "https://aspace.test.org/staff/api#{uri}")
      .to_return(
        status: 200,
        body: File.open(path),
        headers: { "Content-Type": "application/json" }
      )
  end

  # VCR-like caching, because getting the responses is hard.
  def cache_path(uri:, path:)
    return if File.exist?(path)

    WebMock.disable!
    client = cache_client
    client.login
    result = client.get(uri)
    FileUtils.mkdir_p(Pathname.new(path).dirname)
    File.open(path, "w") do |f|
      f.write(result.body)
    end
    WebMock.enable!
    JSON.parse(result.body)
  end

  def cache_client
    ArchivesSpace::Client.new(
      ArchivesSpace::Configuration.new(
        base_uri: Abid.all_environment_config["development"]["archivespace_url"],
        username: Abid.all_environment_config["development"]["archivespace_user"],
        password: Abid.all_environment_config["development"]["archivespace_password"],
        page_size: 50,
        throttle: 0
      )
    )
  end
end

RSpec.configure do |config|
  config.include AspaceStubbing
end

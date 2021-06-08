# frozen_string_literal: true

module AspaceStubbing
  def stub_user(uid:, uri:)
    stub_aspace_login
    stub_request(:get, "https://aspace.test.org/staff/api/users?page=1").to_return(
      status: 200,
      headers: {
        "Content-Type" => "application/json"
      },
      body: {
        first_page: 1,
        last_page: 1,
        this_page: 1,
        total: 1,
        results: [
          {
            lock_version: 1,
            username: uid,
            name: uid,
            is_system_user: false,
            create_time: Time.current.iso8601,
            system_mtime: Time.current.iso8601,
            user_mtime: Time.current.iso8601,
            jsonmodel_type: "user",
            groups: [],
            is_admin: false,
            uri: uri
          }
        ]
      }.to_json
    )
    stub_request(:get, "https://aspace.test.org/staff/api/users?page=2").to_return(
      status: 200,
      headers: {
        "Content-Type" => "application/json"
      },
      body: {
        first_page: 1,
        last_page: 1,
        this_page: 2,
        total: 1,
        results: []
      }.to_json
    )
  end

  def stub_unauthorized_user(uid:, uri:)
    stub_user(uid: uid, uri: uri)
    stub_request(:get, "https://aspace.test.org/staff/api/users/1").to_return(
      status: 200,
      headers: {
        "Content-Type" => "application/json"
      },
      body: unauthorized_user(uid).to_json
    )
  end

  def stub_admin_user(uid:, uri:)
    stub_user(uid: uid, uri: uri)
    stub_request(:get, "https://aspace.test.org/staff/api/users/1").to_return(
      status: 200,
      headers: {
        "Content-Type" => "application/json"
      },
      body: admin_user(uid).to_json
    )
  end

  def stub_staff_user(uid:, uri:)
    stub_user(uid: uid, uri: uri)
    stub_request(:get, "https://aspace.test.org/staff/api/users/1").to_return(
      status: 200,
      headers: {
        "Content-Type" => "application/json"
      },
      body: staff_user(uid).to_json
    )
  end

  def admin_user(uid)
    unauthorized_user(uid).merge(
      "is_admin": true
    )
  end

  def staff_user(uid)
    unauthorized_user(uid).merge(
      "permissions":
      {
        "/repositories/5": ["update_resource_record", "update_digital_object_record", "update_event_record", "delete_event_record", "view_suppressed"],
        "_archivesspace": ["update_subject_record", "delete_subject_record", "update_agent_record", "delete_agent_record", "update_vocabulary_record"]
      }
    )
  end

  def unauthorized_user(uid)
    {
      "lock_version": 15,
      "username": uid,
      "name": uid,
      "is_system_user": false,
      "create_time": "2019-06-06T13:33:54Z",
      "system_mtime": "2019-08-29T14:38:01Z",
      "user_mtime": "2019-08-29T14:38:01Z",
      "jsonmodel_type": "user",
      "groups": [],
      "is_admin": false,
      "uri": "/users/1",
      "permissions": {
        "_archivesspace": []
      }
    }
    #
    # }
  end

  def stub_aspace_login
    stub_request(:post, "https://aspace.test.org/staff/api/users/test/login?password=password").to_return(status: 200, body: { session: "1" }.to_json, headers: { "Content-Type": "application/json" })
    stub_locations
    stub_container_profiles
  end

  def stub_locations
    uri = "/locations?page=1&page_size=100"
    path = Rails.root.join("spec", "fixtures", "aspace", "locations_1.json")
    cache_path(uri: uri, path: path)
    stub_aspace_request(uri: uri, path: path)
  end

  def stub_container_profiles
    uri = "/container_profiles?page=1&page_size=100"
    path = Rails.root.join("spec", "fixtures", "aspace", "container_profiles_1.json")
    cache_path(uri: uri, path: path)
    stub_aspace_request(uri: uri, path: path)
  end

  def stub_repositories
    uri = "/repositories?page=1"
    path = Rails.root.join("spec", "fixtures", "aspace", "repositories_1.json")
    cache_path(uri: uri, path: path)
    stub_aspace_request(uri: uri, path: path)
  end

  def stub_location(ref:)
    path = Rails.root.join("spec", "fixtures", "aspace", "locations", "#{ref.split('/').last}.json")
    cache_path(uri: ref, path: path)
    stub_aspace_request(uri: ref, path: path)
  end

  def stub_container_profile(ref:)
    path = Rails.root.join("spec", "fixtures", "aspace", "container_profiles", "#{ref.split('/').last}.json")
    cache_path(uri: ref, path: path)
    stub_aspace_request(uri: ref, path: path)
  end

  def stub_top_container(ref:)
    path = Rails.root.join("spec", "fixtures", "aspace", "top_containers", "#{ref.split('/').last}.json")
    cache_path(uri: ref, path: path)
    stub_aspace_request(uri: ref, path: path)
  end

  def stub_save_top_container(ref:)
    stub_request(:post, "https://aspace.test.org/staff/api#{ref}")
      .to_return(status: 200, body: "", headers: { "Content-Type" => "application/json" })
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

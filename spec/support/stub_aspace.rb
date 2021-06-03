# frozen_string_literal: true

module AspaceStubbing
  def stub_aspace_login
    stub_request(:post, "https://aspace.test.org/staff/api/users/test/login?password=password").to_return(status: 200, body: { session: "1" }.to_json, headers: { "Content-Type": "application/json" })
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

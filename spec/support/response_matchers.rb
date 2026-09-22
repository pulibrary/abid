# frozen_string_literal: true

require "rspec/expectations"

# rspec-rails supplied `redirect_to`, `have_http_status` and `be_successful`
# against ActionDispatch::TestResponse. They are reimplemented here against
# Rack::MockResponse so the spec examples keep their original wording.
RSpec::Matchers.define :redirect_to do |expected|
  match do |response|
    location = response.headers["location"] || response.headers["Location"]
    response.status.between?(300, 399) && normalize(location) == normalize(expected)
  end

  failure_message do |response|
    location = response.headers["location"] || response.headers["Location"]
    "expected a redirect to #{expected.inspect}, got status #{response.status} " \
      "and location #{location.inspect}"
  end

  def normalize(url)
    return url if url.nil?

    url.to_s.sub(%r{\Ahttps?://[^/]+}, "")
  end
end

RSpec::Matchers.define :have_http_status do |expected|
  STATUS_CODES = {
    ok: 200, created: 201, no_content: 204, found: 302,
    bad_request: 400, unauthorized: 401, forbidden: 403, not_found: 404,
    unprocessable_entity: 422, service_unavailable: 503, internal_server_error: 500
  }.freeze

  match do |response|
    case expected
    when Symbol then response.status == STATUS_CODES.fetch(expected)
    when Integer then response.status == expected
    when :success, :successful then response.status.between?(200, 299)
    end
  end

  failure_message do |response|
    "expected HTTP status #{expected.inspect}, got #{response.status}"
  end
end

module ResponsePredicates
  # `expect(response).to be_successful`
  def successful? = status.between?(200, 299)
end

Rack::MockResponse.include(ResponsePredicates)

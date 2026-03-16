# frozen_string_literal: true

require "test_helper"

class TestOpenidConfigParser < Minitest::Test
  def setup
    OpenidConfigParser.reset_configuration!
    OpenidConfigParser.clear_cache!

    @valid_endpoint = "https://valid.url/.well-known/openid-configuration"
    @invalid_endpoint = "not a valid url @@"

    @valid_response = {
      issuer: "https://valid.url",
      authorization_endpoint: "https://valid.url/authorization",
      token_endpoint: "https://valid.url/token",
      jwks_uri: "https://valid.url/jwks",
      userinfo_endpoint: "https://valid.url/userinfo",
      scopes_supported: %w[openid email profile groups],
      grant_types_supported: ["authorization_code"],
      response_modes_supported: %w[query fragment form_post],
      token_endpoint_auth_methods: %w[client_secret_basic client_secret_post],
      response_types_supported: ["code"],
      subject_types_supported: ["public"],
      id_token_signing_alg_values_supported: ["RS256"]
    }.to_json
  end

  def test_that_it_has_a_version_number
    refute_nil ::OpenidConfigParser::VERSION
  end

  def test_fetch_openid_configuration_success
    stub_request(:get, @valid_endpoint)
      .to_return(status: 200, body: @valid_response, headers: {"Content-Type" => "application/json"})

    config = OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)

    refute_nil config
    assert_equal "https://valid.url", config[:issuer]
    assert_equal "https://valid.url", config["issuer"]
  end

  def test_config_elements_as_methods
    stub_request(:get, @valid_endpoint)
      .to_return(status: 200, body: @valid_response, headers: {"Content-Type" => "application/json"})

    config = OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)

    refute_nil config
    assert_equal "https://valid.url", config.issuer
    assert_equal "https://valid.url/authorization", config.authorization_endpoint
    assert_equal %w[openid email profile groups], config.scopes_supported
  end

  def test_config_to_h
    stub_request(:get, @valid_endpoint)
      .to_return(status: 200, body: @valid_response, headers: {"Content-Type" => "application/json"})

    config = OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)

    assert_instance_of Hash, config.to_h
    assert_equal "https://valid.url", config.to_h[:issuer]
  end

  def test_invalid_url_error
    error = assert_raises(OpenidConfigParser::Error) do
      OpenidConfigParser.fetch_openid_configuration(@invalid_endpoint)
    end

    assert_match(/Invalid URL provided/, error.message)
  end

  def test_json_parser_error
    stub_request(:get, @valid_endpoint)
      .to_return(status: 200, body: "invalid json", headers: {"Content-Type" => "application/json"})

    error = assert_raises(OpenidConfigParser::Error) do
      OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)
    end

    assert_match(/Failed to parse JSON response/, error.message)
  end

  def test_network_timeout_error
    stub_request(:get, @valid_endpoint).to_timeout

    error = assert_raises(OpenidConfigParser::Error) do
      OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)
    end

    assert_match(/Network timeout error/, error.message)
  end

  def test_socket_error
    stub_request(:get, @valid_endpoint).to_raise(SocketError)

    error = assert_raises(OpenidConfigParser::Error) do
      OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)
    end

    assert_match(/Failed to open TCP connection/, error.message)
  end

  def test_standard_error
    stub_request(:get, @valid_endpoint).to_raise(StandardError.new("An unexpected error"))

    error = assert_raises(OpenidConfigParser::Error) do
      OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)
    end

    assert_match(/An unexpected error occurred/, error.message)
  end

  def test_http_error_status
    stub_request(:get, @valid_endpoint)
      .to_return(status: 404, body: "Not Found")

    error = assert_raises(OpenidConfigParser::Error) do
      OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)
    end

    assert_match(/HTTP 404/, error.message)
  end

  def test_caching
    stub_request(:get, @valid_endpoint)
      .to_return(status: 200, body: @valid_response, headers: {"Content-Type" => "application/json"})

    config1 = OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)
    config2 = OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)

    assert_same config1, config2
    assert_requested(:get, @valid_endpoint, times: 1)
  end

  def test_clear_cache
    stub_request(:get, @valid_endpoint)
      .to_return(status: 200, body: @valid_response, headers: {"Content-Type" => "application/json"})

    OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)
    OpenidConfigParser.clear_cache!
    OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)

    assert_requested(:get, @valid_endpoint, times: 2)
  end

  def test_configuration
    OpenidConfigParser.configure do |config|
      config.open_timeout = 10
      config.read_timeout = 15
      config.retries = 5
      config.cache_ttl = 1800
      config.validate = false
    end

    assert_equal 10, OpenidConfigParser.configuration.open_timeout
    assert_equal 15, OpenidConfigParser.configuration.read_timeout
    assert_equal 5, OpenidConfigParser.configuration.retries
    assert_equal 1800, OpenidConfigParser.configuration.cache_ttl
    assert_equal false, OpenidConfigParser.configuration.validate
  end

  def test_validation_missing_fields
    incomplete_response = {issuer: "https://valid.url"}.to_json

    stub_request(:get, @valid_endpoint)
      .to_return(status: 200, body: incomplete_response, headers: {"Content-Type" => "application/json"})

    error = assert_raises(OpenidConfigParser::Error) do
      OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)
    end

    assert_match(/Missing required OIDC fields/, error.message)
  end

  def test_validation_can_be_disabled
    incomplete_response = {issuer: "https://valid.url"}.to_json

    OpenidConfigParser.configure do |config|
      config.validate = false
    end

    stub_request(:get, @valid_endpoint)
      .to_return(status: 200, body: incomplete_response, headers: {"Content-Type" => "application/json"})

    config = OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)
    assert_equal "https://valid.url", config.issuer
  end

  def test_retries_on_timeout
    OpenidConfigParser.configure do |config|
      config.retries = 3
    end

    stub_request(:get, @valid_endpoint)
      .to_timeout
      .to_timeout
      .to_return(status: 200, body: @valid_response, headers: {"Content-Type" => "application/json"})

    config = OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)
    assert_equal "https://valid.url", config.issuer
    assert_requested(:get, @valid_endpoint, times: 3)
  end

  def test_fetch_userinfo_with_config_object
    userinfo_response = {sub: "user123", email: "user@example.com", name: "Test User"}.to_json

    stub_request(:get, @valid_endpoint)
      .to_return(status: 200, body: @valid_response, headers: {"Content-Type" => "application/json"})
    stub_request(:get, "https://valid.url/userinfo")
      .with(headers: {"Authorization" => "Bearer test_token"})
      .to_return(status: 200, body: userinfo_response, headers: {"Content-Type" => "application/json"})

    config = OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)
    user_info = OpenidConfigParser.fetch_userinfo(config, access_token: "test_token")

    assert_equal "user123", user_info[:sub]
    assert_equal "user@example.com", user_info[:email]
    assert_equal "Test User", user_info[:name]
  end

  def test_fetch_userinfo_with_endpoint_url
    userinfo_response = {sub: "user123", email: "user@example.com"}.to_json

    stub_request(:get, @valid_endpoint)
      .to_return(status: 200, body: @valid_response, headers: {"Content-Type" => "application/json"})
    stub_request(:get, "https://valid.url/userinfo")
      .with(headers: {"Authorization" => "Bearer my_token"})
      .to_return(status: 200, body: userinfo_response, headers: {"Content-Type" => "application/json"})

    user_info = OpenidConfigParser.fetch_userinfo(@valid_endpoint, access_token: "my_token")

    assert_equal "user123", user_info[:sub]
    assert_equal "user@example.com", user_info[:email]
  end

  def test_fetch_userinfo_missing_endpoint
    stub_request(:get, @valid_endpoint)
      .to_return(status: 200, body: @valid_response, headers: {"Content-Type" => "application/json"})

    config = OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)
    config[:userinfo_endpoint] = nil

    error = assert_raises(OpenidConfigParser::Error) do
      OpenidConfigParser.fetch_userinfo(config, access_token: "test_token")
    end

    assert_match(/No userinfo_endpoint found/, error.message)
  end

  def test_fetch_userinfo_http_error
    stub_request(:get, @valid_endpoint)
      .to_return(status: 200, body: @valid_response, headers: {"Content-Type" => "application/json"})
    stub_request(:get, "https://valid.url/userinfo")
      .to_return(status: 401, body: "Unauthorized")

    config = OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)

    error = assert_raises(OpenidConfigParser::Error) do
      OpenidConfigParser.fetch_userinfo(config, access_token: "bad_token")
    end

    assert_match(/HTTP 401/, error.message)
  end

  def test_deep_symbolize_keys_with_nested_hash
    nested_response = {
      issuer: "https://valid.url",
      authorization_endpoint: "https://valid.url/authorization",
      jwks_uri: "https://valid.url/jwks",
      response_types_supported: ["code"],
      subject_types_supported: ["public"],
      id_token_signing_alg_values_supported: ["RS256"],
      nested: {inner_key: "inner_value"}
    }.to_json

    stub_request(:get, @valid_endpoint)
      .to_return(status: 200, body: nested_response, headers: {"Content-Type" => "application/json"})

    config = OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)
    assert_equal "inner_value", config.nested[:inner_key]
  end
end

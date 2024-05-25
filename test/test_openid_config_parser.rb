# frozen_string_literal: true

require "test_helper"

class TestOpenidConfigParser < Minitest::Test
  def setup
    @valid_endpoint = "https://valid.url/.well-known/openid-configuration"
    @invalid_endpoint = "https://invalid.url/.well-known/openid-configuration"

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
      response_types_supported: ["code"]
    }.to_json
  end

  def test_that_it_has_a_version_number
    refute_nil ::OpenidConfigParser::VERSION
  end

  def test_fetch_openid_configuration_success
    stub_request(:get, @valid_endpoint).to_return(body: @valid_response,
                                                  headers: { "Content-Type" => "application/json" })

    config = OpenidConfigParser.fetch_openid_configuration(@valid_endpoint)

    refute_nil config
    assert_equal "https://valid.url", config[:issuer]
    assert_equal "https://valid.url", config["issuer"]
  end

  def test_invalid_url_error
    stub_request(:get, @invalid_endpoint).to_raise(URI::InvalidURIError)

    error = assert_raises(OpenidConfigParser::Error) do
      OpenidConfigParser.fetch_openid_configuration(@invalid_endpoint)
    end

    assert_match(/Invalid URL provided/, error.message)
  end

  def test_json_parser_error
    stub_request(:get, @valid_endpoint).to_return(body: "invalid json",
                                                  headers: { "Content-Type" => "application/json" })

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
end

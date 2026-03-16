# frozen_string_literal: true

require_relative "openid_config_parser/version"
require "net/http"
require "json"
require "uri"

module OpenidConfigParser
  class Error < StandardError; end

  REQUIRED_FIELDS = %i[
    issuer
    authorization_endpoint
    jwks_uri
    response_types_supported
    subject_types_supported
    id_token_signing_alg_values_supported
  ].freeze

  class Configuration
    attr_accessor :open_timeout, :read_timeout, :retries, :cache_ttl, :validate

    def initialize
      @open_timeout = 5
      @read_timeout = 5
      @retries = 3
      @cache_ttl = 900
      @validate = true
    end
  end

  class Config
    def initialize(data)
      @data = data
    end

    def [](key)
      @data[key.to_sym]
    end

    def []=(key, value)
      @data[key.to_sym] = value
    end

    def to_h
      @data.dup
    end

    def respond_to_missing?(method_name, include_private = false)
      @data.key?(method_name) || super
    end

    def method_missing(method_name, *args)
      if method_name.end_with?("=") && args.length == 1
        @data[method_name.to_s.chomp("=").to_sym] = args.first
      elsif @data.key?(method_name)
        @data[method_name]
      else
        super
      end
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    def fetch_openid_configuration(endpoint_url)
      cached = read_cache(endpoint_url)
      return cached if cached

      response_body = fetch_with_retries(endpoint_url)
      data = parse_json(response_body)
      symbolized = deep_symbolize_keys(data)
      validate!(symbolized) if configuration.validate
      config = Config.new(symbolized)
      write_cache(endpoint_url, config)
      config
    end

    def fetch_userinfo(config_or_endpoint_url, access_token:)
      config = if config_or_endpoint_url.is_a?(Config)
        config_or_endpoint_url
      else
        fetch_openid_configuration(config_or_endpoint_url)
      end

      userinfo_url = config[:userinfo_endpoint]
      raise Error, "No userinfo_endpoint found in OIDC configuration" unless userinfo_url

      response_body = fetch_with_retries(userinfo_url, headers: {
        "Authorization" => "Bearer #{access_token}",
        "Content-Type" => "application/json"
      })
      data = parse_json(response_body)
      deep_symbolize_keys(data)
    end

    def clear_cache!
      @cache = {}
    end

    private

    def fetch_with_retries(endpoint_url, headers: {})
      uri = URI(endpoint_url)
      attempts = 0

      begin
        attempts += 1
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = configuration.open_timeout
        http.read_timeout = configuration.read_timeout

        request = Net::HTTP::Get.new(uri)
        headers.each { |key, value| request[key] = value }
        response = http.request(request)

        unless response.is_a?(Net::HTTPSuccess)
          raise Error, "HTTP #{response.code}: #{response.message}"
        end

        response.body
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        retry if attempts < configuration.retries
        raise Error, "Network timeout error: #{e.message}"
      end
    rescue URI::InvalidURIError => e
      raise Error, "Invalid URL provided: #{e.message}"
    rescue SocketError => e
      raise Error, "Failed to open TCP connection: #{e.message}"
    rescue Error
      raise
    rescue => e
      raise Error, "An unexpected error occurred: #{e.message}"
    end

    def parse_json(body)
      JSON.parse(body)
    rescue JSON::ParserError => e
      raise Error, "Failed to parse JSON response: #{e.message}"
    end

    def deep_symbolize_keys(hash)
      hash.each_with_object({}) do |(key, value), result|
        result[key.to_sym] = value.is_a?(Hash) ? deep_symbolize_keys(value) : value
      end
    end

    def validate!(data)
      missing = REQUIRED_FIELDS.select { |field| data[field].nil? }
      return if missing.empty?

      raise Error, "Missing required OIDC fields: #{missing.join(", ")}"
    end

    def cache
      @cache ||= {}
    end

    def read_cache(key)
      entry = cache[key]
      return nil unless entry
      return nil if Time.now - entry[:time] > configuration.cache_ttl

      entry[:value]
    end

    def write_cache(key, value)
      cache[key] = {value: value, time: Time.now}
    end
  end
end

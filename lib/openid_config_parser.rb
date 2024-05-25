# frozen_string_literal: true

require_relative "openid_config_parser/version"
require "net/http"
require "json"
require "uri"
require "retryable"

# OpenidConfigParser is a module that fetches and parses OpenID Connect
# configuration data from a specified endpoint URL and returns a Hash object.
# It includes error handling to manage various issues that might occur
# during the HTTP request and JSON parsing process.
module OpenidConfigParser
  class Error < StandardError; end

  class << self
    # Recursively converts keys of a hash to symbols while retaining the original string keys.
    def deep_symbolize_keys(hash)
      result = {}
      hash.each do |key, value|
        sym_key = key.to_sym
        result[sym_key] = value.is_a?(Hash) ? deep_symbolize_keys(value) : value
        result[key] = result[sym_key] # Add the string key as well
      end
      result
    end

    def fetch_user_info(access_token)
      Retryable.retryable(tries: 3, on: [Net::ReadTimeout, Net::OpenTimeout]) do
        response = HTTParty.get(ENV["CLOUDFLARE_USERINFO_ENDPOINT"], {
                                  headers: {
                                    "Authorization" => "Bearer #{access_token}",
                                    "Content-Type" => "application/json"
                                  },
                                  timeout: 10
                                })
        return response.parsed_response
      end
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      puts "Timeout error: #{e.message}"
      nil
    end

    def fetch_openid_configuration(endpoint_url)
      uri = URI(endpoint_url)
      Retryable.retryable(tries: 3, on: [Net::ReadTimeout, Net::OpenTimeout]) do
        response = Net::HTTP.get(uri)
        config = JSON.parse(response)
        return deep_symbolize_keys(config)
      end
    rescue JSON::ParserError => e
      raise Error, "Failed to parse JSON response: #{e.message}"
    rescue URI::InvalidURIError => e
      raise Error, "Invalid URL provided: #{e.message}"
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise Error, "Network timeout error: #{e.message}"
    rescue SocketError => e
      raise Error, "Failed to open TCP connection: #{e.message}"
    rescue StandardError => e
      raise Error, "An unexpected error occurred: #{e.message}"
    end
  end
end

# OpenidConfigParser

`openid_config_parser` is a lightweight, zero-dependency Ruby gem that fetches and parses
OpenID Connect configuration data from a specified endpoint URL. It includes built-in
caching, automatic retries, OIDC field validation, and configurable timeouts.

## Installation

To install the gem run the following command in the terminal:

    $ bundle add openid_config_parser

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install openid_config_parser

## Usage

For non-Rails application you might need to require the gem in your file like so:

```ruby
require 'openid_config_parser'
```

### Fetching configuration

```ruby
endpoint = "https://example.com/.well-known/openid-configuration"
config = OpenidConfigParser.fetch_openid_configuration(endpoint)

config.issuer                  # => "https://example.com"
config[:authorization_endpoint] # => "https://example.com/authorize"
config["jwks_uri"]             # => "https://example.com/.well-known/jwks.json"
config.to_h                    # => { issuer: "...", ... }
```

### Configuration

```ruby
OpenidConfigParser.configure do |config|
  config.open_timeout = 10   # seconds (default: 5)
  config.read_timeout = 10   # seconds (default: 5)
  config.retries      = 5    # retry attempts on timeout (default: 3)
  config.cache_ttl    = 3600 # cache lifetime in seconds (default: 900)
  config.validate     = false # disable OIDC field validation (default: true)
end
```

### Fetching user info

Fetch user information from the OIDC `userinfo_endpoint` using an access token.
Works with any OIDC provider (Cloudflare, Google, Azure AD, etc.).

```ruby
# With a previously fetched config object
config = OpenidConfigParser.fetch_openid_configuration(endpoint)
user_info = OpenidConfigParser.fetch_userinfo(config, access_token: "your_access_token")

user_info[:sub]   # => "user123"
user_info[:email] # => "user@example.com"
user_info[:name]  # => "Test User"

# Or pass the discovery endpoint URL directly (config is fetched automatically)
user_info = OpenidConfigParser.fetch_userinfo(endpoint, access_token: "your_access_token")
```

### Caching

Responses are cached in memory for the duration of `cache_ttl` (default: 15 minutes).
Subsequent calls with the same endpoint URL return the cached result without making
an HTTP request.

```ruby
OpenidConfigParser.clear_cache! # manually clear all cached configurations
```

### OIDC validation

By default, the gem validates that the response includes the required fields defined
in the [OpenID Connect Discovery specification](https://openid.net/specs/openid-connect-discovery-1_0.html):
`issuer`, `authorization_endpoint`, `jwks_uri`, `response_types_supported`,
`subject_types_supported`, and `id_token_signing_alg_values_supported`.

Validation can be disabled via configuration if needed.

### Error handling

All errors are wrapped in `OpenidConfigParser::Error`:

```ruby
begin
  config = OpenidConfigParser.fetch_openid_configuration(endpoint)
rescue OpenidConfigParser::Error => e
  puts e.message
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/msuliq/openid_config_parser. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/msuliq/openid_config_parser/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OpenidConfigParser project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/msuliq/openid_config_parser/blob/main/CODE_OF_CONDUCT.md).

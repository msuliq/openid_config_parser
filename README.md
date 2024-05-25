# OpenidConfigParser

`openid_config_parser` is a lightweight Rubygem containing a method that fetches and
parses OpenID Connect configuration data from a specified endpoint URL and returns a Hash
object. It includes error handling to manage various issues that might occur during the
HTTP request and JSON parsing process.

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

You can use the `openid_config_parser` in any of your Rails controllers, models, or
other parts of your application.

```ruby
# app/controllers/application_controller.rb

class ApplicationController < ActionController::Base
  def fetch_openid_config
    endpoint = "https://example.com/.well-known/openid-configuration"
    config = OpenidConfigParser.fetch_openid_configuration(endpoint)

    if config
      issuer = config[:issuer]
      auth_endpoint = config[:authorization_endpoint]
      token_endpoint = config[:token_endpoint]
      jwks_uri = config[:]
      userinfo_endpoint = config[:userinfo_endpoint]
      # and so on
    else
      Rails.logger.error "Failed to fetch OpenID configuration"
    end
  rescue OpenidConfigParser::Error => e
    Rails.logger.error "Error fetching OpenID configuration: #{e.message}"
  end
end
```

Considering that HTTP request is made to fetch the endpoint configuration, you can call
this method in a background job for optimized performance.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/msuliq/openid_config_parser. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/msuliq/openid_config_parser/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OpenidConfigParser project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/msuliq/openid_config_parser/blob/main/CODE_OF_CONDUCT.md).

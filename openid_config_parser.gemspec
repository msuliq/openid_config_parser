# frozen_string_literal: true

require_relative "lib/openid_config_parser/version"

Gem::Specification.new do |spec|
  spec.name = "openid_config_parser"
  spec.version = OpenidConfigParser::VERSION
  spec.authors = ["Suleyman Musayev"]
  spec.email = ["slmusayev@gmail.com"]

  spec.summary = "Fetch data from OpenID Connect (OIDC) configuration endpoint and parse it as a Hash object"
  spec.description = "`openid_config_parser` is a lightweight Ruby gem designed to fetch and parse
    OpenID Connect configuration data from any specified endpoint URL.
    Whether you are building an authentication system or integrating with an OpenID Connect provider,
    this gem provides a simple and efficient way to retrieve and handle the necessary configuration details."
  spec.homepage = "https://github.com/msuliq/openid_config_parser"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/msuliq/openid_config_parser"
  spec.metadata["changelog_uri"] = "https://github.com/msuliq/openid_config_parser/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end

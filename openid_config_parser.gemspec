# frozen_string_literal: true

require_relative "lib/openid_config_parser/version"

Gem::Specification.new do |spec|
  spec.name = "openid_config_parser"
  spec.version = OpenidConfigParser::VERSION
  spec.authors = ["Suleyman Musayev"]
  spec.email = ["slmusayev@gmail.com"]

  spec.summary = "Fetch and parse OpenID Connect configuration endpoints"
  spec.description = "`openid_config_parser` is a lightweight, zero-dependency Ruby gem that fetches and parses " \
    "OpenID Connect configuration data from any specified endpoint URL. " \
    "It provides built-in caching, retries, OIDC field validation, and configurable timeouts."
  spec.homepage = "https://github.com/msuliq/openid_config_parser"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/msuliq/openid_config_parser"
  spec.metadata["changelog_uri"] = "https://github.com/msuliq/openid_config_parser/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end

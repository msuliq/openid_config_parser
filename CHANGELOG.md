## [Released]

## [0.3.0] - 2026-03-16

### Breaking Changes
- Removed `retryable` runtime dependency — the gem now has zero runtime dependencies
- Replaced `fetch_user_info` with `fetch_userinfo(config_or_endpoint_url, access_token:)` — now provider-agnostic, uses `Net::HTTP` instead of `HTTParty`, and reads the `userinfo_endpoint` from the OIDC config rather than a hardcoded environment variable
- `Config` no longer inherits from `OpenStruct` — replaced with a custom class backed by a plain `Hash`
- `deep_symbolize_keys` no longer stores duplicate string keys alongside symbol keys; all keys are symbols only
- String key access via `config["key"]` still works — it is converted to a symbol in the `Config#[]` accessor

### Added
- **Configurable settings** via `OpenidConfigParser.configure` block:
  - `open_timeout` — HTTP open timeout in seconds (default: 5)
  - `read_timeout` — HTTP read timeout in seconds (default: 5)
  - `retries` — number of retry attempts on timeout (default: 3)
  - `cache_ttl` — cache lifetime in seconds (default: 900 / 15 minutes)
  - `validate` — toggle OIDC field validation (default: true)
- **In-memory caching** — repeated calls with the same endpoint URL return a cached result without an HTTP request; cache can be cleared with `OpenidConfigParser.clear_cache!`
- **OIDC field validation** — responses are validated against required fields from the OpenID Connect Discovery spec (`issuer`, `authorization_endpoint`, `jwks_uri`, `response_types_supported`, `subject_types_supported`, `id_token_signing_alg_values_supported`); can be disabled via configuration
- **HTTP status code checking** — non-2xx responses now raise `OpenidConfigParser::Error` with the status code (e.g. `HTTP 404: Not Found`) instead of attempting to parse the body as JSON
- **`fetch_userinfo(config_or_endpoint_url, access_token:)`** — fetches user info from the OIDC `userinfo_endpoint`; accepts either a `Config` object or a discovery endpoint URL; works with any OIDC provider (Cloudflare, Google, Azure AD, etc.)
- **`Config#to_h`** — returns a duplicate of the underlying hash for easy serialization
- **`OpenidConfigParser.reset_configuration!`** — resets all settings to defaults

### Changed
- Retry logic reimplemented using a simple `begin/retry` loop, removing the `retryable` gem dependency
- `Config` class uses `method_missing` / `respond_to_missing?` backed by a frozen-key hash instead of `OpenStruct`
- HTTP requests now use `Net::HTTP.new` with explicit `open_timeout` and `read_timeout` instead of `Net::HTTP.get`
- `rescue StandardError` narrowed — `OpenidConfigParser::Error` is re-raised without wrapping

### Development / CI
- Replaced `rubocop` with `standardrb` for linting
- Replaced `bundle-audit` gem with `bundler-audit`
- GitHub Actions PR workflow now has separate `standardrb`, `bundle-audit`, and `test` jobs
- Test matrix updated from Ruby 2.7 / 3.2.1 to Ruby 2.7 / 3.1 / 3.3
- Deployment workflow updated to Ruby 3.3
- Test suite expanded from 8 to 17 tests covering caching, configuration, HTTP errors, validation, retries, and nested hashes
- Updated transitive dependencies (`rexml`, `thor`) to resolve security advisories

## [0.2.4] - 2025-10-11
- Dependencies update

## [0.2.3] - 2024-06-16
- Actions update

## [0.2.2] - 2024-06-16
- Add dependabot

## [0.2.1] - 2024-06-05
- Fix reference to retryable

## [0.2.0] - 2024-06-04
- Add retryable, add support to access response values as methods

## [0.1.2] - 2024-05-25
- Add support for ruby >=2.7

## [0.1.1] - 2024-05-25
- Update readme

## [0.1.0] - 2024-05-25
- Initial release

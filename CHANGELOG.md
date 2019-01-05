# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

As this is an unoficial fork, no actual Gems are released for any version.

## [1.1.0] - 2019-01-05

### Added
- Support for the Azure v2.0 AD openidconnect endpoint
- option to run a single provider for multiple AD tenants
- support for password reset requests

### Changed
- Updated JWT dependency to ~> 2.0

### Fixed
- use a configured on\_failure error handler instead of always raising
  exceptions in callback\_phase



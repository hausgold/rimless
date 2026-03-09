# WaterDrop RubyGem (relevant changes)

* See: https://github.com/karafka/waterdrop/blob/master/CHANGELOG.md
* Migrated the `waterdrop` gem from `~> 1.4` to `~> 2.8`

---

- [Important](#important)
- [Minor](#minor)

## Important

* Replaced `ruby-kafka` with `rdkafka` (karafka-rdkafka, native gem/lib)
* The new underlying Kafka library has different/renamed options (see:
  https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md)
* No `dry-*` gems are used as dependencies anymore
* Complete redesign of the API (this is wrapped by Rimless helpers, which
  remained stable)
* All time-related values are now configured in milliseconds instead of some
  being in seconds and some in milliseconds

## Minor

* Added support for sending tombstone messages
* Changed auto-generated ID from `SecureRandom#uuid` to `SecureRandom#hex(6)`
* Introduced transactions support
* Added support for producing messages with arrays of strings in headers
  (KIP-82)
* Added `WaterDrop::ConnectionPool` for efficient connection pooling using the
  proven `connection_pool` gem

# Karafka RubyGem (relevant changes)

* See: https://github.com/karafka/karafka/blob/master/CHANGELOG.md
* See: https://github.com/karafka/karafka/wiki/Upgrades-Karafka-2.0
* Migrated the `karafka` gem from `~> 1.4` to `~> 2.5`

---

- [Important (Structural)](#important-structural)
- [Important (Logical)](#important-logical)
- [Important (Configurations)](#important-configurations)
- [Important (End-user code changes)](#important-end-user-code-changes)
- [Minor](#minor)

## Important (Structural)

* Removed the topic mappers concept completely
* Removed support for using sidekiq-backend due to the introduction of
  multi-threading
  * Removed the now incompatible `karafka-sidekiq-backend` gem
  * If you use sidekiq-backend, you have two options:
    * Leverage Karafka's multi-threading capabilities
    * Pipe the jobs to Sidekiq yourself (this is what we do with the Rimless
      gem now)
* Removed the Responders concept in favor of WaterDrop producer usage
* Removed all callbacks completely in favor of the finalizer method `#shutdown`
* Removed single message consumption mode in favor of documentation on how to
  do it easily yourself (see:
  https://github.com/karafka/karafka/wiki/Consuming-messages#consuming-messages-one-at-a-time)
  * In the past, Rimless configured `config.batch_fetching = true` and
    `config.batch_consuming = false`, resulting in single message processing
    within the Karafka process, but each Kafka message was enqueued as a
    Sidekiq worker/job — so message consumption was always concurrent. Batch
    fetching is now always done by Karafka; adjust `config.max_wait_time` or
    `config.max_messages` to optimize for latency or throughput (also check
    `config.kafka[:'enable.partition.eof'] = true`, see:
    https://karafka.io/docs/Latency-and-Throughput/).
* Renamed `Karafka::Params::BatchMetadata` to
  `Karafka::Messages::BatchMetadata`
* Renamed `Karafka::Params::Params` to `Karafka::Messages::Message`
* Renamed `#params_batch` in consumers to `#messages` (Rimless adds a
  compatibility delegation for the old `#params_batch`)
* Renamed `Karafka::Params::Metadata` to `Karafka::Messages::Metadata`
* Renamed `Karafka::Fetcher` to `Karafka::Runner` and aligned notification key
  names
* Renamed `Karafka::Instrumentation::StdoutListener` to
  `Karafka::Instrumentation::LoggerListener`
* Renamed `Karafka::Serializers::JSON::Deserializer` to
  `Karafka::Deserializers::Payload`

## Important (Logical)

* Changed how the routing style (0.5) behaves. It now builds a single consumer
  group instead of one per topic (consumer groups: 2.0 uses 1 for all topics,
  1.4 used 1 per topic)
* Karafka 2.0 introduces seamless Ruby on Rails integration via `Rails::Railtie`
  without needing extra configuration (this is reflected in the Rimless gem,
  as we no longer initialize the Rails application)

## Important (Configurations)

* Karafka 2.0 is powered by librdkafka, Rimless allows configuration via
  `Rimless.configuration.consumer_configure` and the configuration is split
  into Karafka settings (root level, see:
  https://github.com/karafka/karafka/blob/v2.5.5/lib/karafka/setup/config.rb)
  and Kafka settings (`config.kafka`, see:
  https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md)
* Below you can find some of the most significant naming changes in the
  configuration options:
  * Root options:
    * `start_from_beginning` is now `initial_offset` and accepts either
      'earliest' or 'latest'
    * `ssl_ca_certs_from_system` is no longer needed, but `kafka`
      `security.protocol` needs to be set to `ssl`
    * `batch_fetching` is no longer needed
    * `batch_consuming` is no longer needed
    * `serializer` is no longer needed because Responders have been removed
      from Karafka
    * `topic_mapper` is no longer needed, as the concept of mapping topic names
      has been removed from Karafka
    * `backend` is no longer needed because Karafka is now multi-threaded
    * `manual_offset_management` now needs to be set on a per-topic basis
  * Kafka options:
    * `kafka.seed_brokers` is now `bootstrap.servers` without the protocol
      definition
    * `kafka.heartbeat_interval` is no longer needed.
    * SASL and SSL options changes are described in their own section.

## Important (End-user code changes)

* Remove WaterDrop setup code from your `karafka.rb`:
```ruby
# This can be safely removed
monitor.subscribe('app.initialized') do
  WaterDrop.setup { |config| config.deliver = !Karafka.env.test? }
end
```
* Remove direct WaterDrop listener references from your `karafka.rb`:
```ruby
# This can be safely removed
Karafka.monitor.subscribe(WaterDrop::Instrumentation::LoggerListener.new)
```
* Remove the `KarafkaApp.boot!` from the end of `karafka.rb`:
```ruby
# Remove this
KarafkaApp.boot!
# or in case of Rimless:
Rimless.consumer.topics(...).boot! # just the `.boot!` call
```

## Minor

* No `dry-*` gems are used as dependencies anymore
* Added `KARAFKA_REQUIRE_RAILS` to disable the default Rails require, to run
  Karafka without Rails despite having Rails in the Gemfile
* Allow running boot-file-less Rails setup Karafka CLI commands where
  configuration is done in initializers

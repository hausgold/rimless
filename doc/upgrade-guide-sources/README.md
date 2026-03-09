# Top Level Overview

- [Dependency Changes](#dependency-changes)
- [Structural Changes](#structural-changes)
  - [Removed](#removed)
  - [Moved, API unchanged, constants changed](#moved-api-unchanged-constants-changed)
  - [Moved, API mostly unchanged, constants changed](#moved-api-mostly-unchanged-constants-changed)
  - [Moved, API unchanged](#moved-api-unchanged)
  - [Logic changed](#logic-changed)
- [Configuration Changes](#configuration-changes)
  - [Changed](#changed)
  - [New](#new)
- [Producer (WaterDrop)](#producer-waterdrop)
- [Consumer Setup (Karafka)](#consumer-setup-karafka)
  - [Karafka 2 (New)](#karafka-2-new)
    - [Phase 1: Boot](#phase-1-boot)
    - [Phase 2: Message Consumption (batch fetching, single consumption)](#phase-2-message-consumption-batch-fetching-single-consumption)
  - [Karafka 1 (Old)](#karafka-1-old)
    - [Phase 1: Boot](#phase-1-boot-1)
    - [Phase 2: Message Consumption (batch fetching, single consumption)](#phase-2-message-consumption-batch-fetching-single-consumption-1)
- [Testing](#testing)

## Dependency Changes

* Migrated the `avro_turf` gem from `~> 0.11.0` to `~> 1.20`
* Migrated the `waterdrop` gem from `~> 1.4` to `~> 2.8`
* Migrated the `karafka` gem from `~> 1.4` to `~> 2.5`
* Switched from Sidekiq to ActiveJob (and added the dependency)

## Structural Changes

### Removed

* lib/rimless/karafka/base64_interchanger.rb
  `Rimless::Karafka::Base64Interchanger` (no interchanging needed, as we do not
  move the avro/binary encoded kafka message payload from Karafka to Sidekiq
  anymore — instead we decode the message payload within the Karafka process,
  and move the decoded data to ActiveJob and use the regular ActiveJob
  arguments serialization)
* lib/rimless/karafka/passthrough_mapper.rb
  `Rimless::Karafka::PassthroughMapper` (Karafka removed consumer/topics
  mapper concepts completely — which was effectively a no-op, as Rimless
  implemented a passthrough mapper to just keep inputs equal to outputs for
  these names)
* lib/rimless/compatibility/karafka_1_4.rb (dropped Karafka 1.x support)

### Moved, API unchanged, constants changed

* lib/rimless/karafka/avro_deserializer.rb `Rimless::Karafka::AvroDeserializer`
  -> lib/rimless/consumer/avro_deserializer.rb
  `Rimless::Consumer::AvroDeserializer`

### Moved, API mostly unchanged, constants changed

* lib/rimless/consumer.rb `Rimless::ConsumerApp` -> lib/rimless/consumer/app.rb
  `Rimless::Consumer::App` (functionality is kept, but some methods were
  removed)
* lib/rimless/consumer_job.rb `Rimless::ConsumerJob` ->
  lib/rimless/consumer/job.rb `Rimless::Consumer::Job` (Sidekiq -> ActiveJob)
* lib/rimless/base_consumer.rb `Rimless::BaseConsumer` ->
  lib/rimless/consumer/base.rb `Rimless::Consumer::Base` (all
  functionality/methods kept, API extended, `#consume` now returns the
  `#messages` array instead of the result of the dispatched event method)

### Moved, API unchanged

* lib/rimless/avro_helpers.rb -> lib/rimless/extensions/avro_helpers.rb
* lib/rimless/configuration_handling.rb ->
  lib/rimless/extensions/configuration_handling.rb
* lib/rimless/kafka_helpers.rb -> lib/rimless/extensions/kafka_helpers.rb
* lib/rimless/dependencies.rb -> lib/rimless/extensions/dependencies.rb

### Logic changed

* lib/rimless/railtie.rb (Karafka is no longer initialized within a Sidekiq
  server context; this was needed in the past for the encoded/binary Kafka
  message payload interchanging, as the data was actually parsed within the
  Sidekiq process)

## Configuration Changes

### Changed

* `KAFKA_BROKERS` (env var) / `config.kafka_brokers` (format change — no
  protocol anymore, just host:port CSV, old format:
  `kafka://your.domain:9092,kafka..`, new format: `your.domain:9092,host..`) —
  the old format is still supported for compatibility

### New

* `config.consumer_logger_listener` (allows configuring the Karafka logging,
  or providing a custom solution)
* `config.job_bridge_class` (allows configuring a custom job bridge class
  that takes care of receiving Kafka messages and producing/enqueuing ActiveJob
  jobs)
* `config.consumer_job_class` (allows configuring a custom job class that
  processes the enqueued Kafka messages produced by the job bridge)
* `config.avro_deserializer_class` (allows configuring a custom Apache Avro
  deserializer class that may implement additional parsing/processing, for
  example)
* `config.avro_configure` (allows users to fully customize the
  `AvroTurf::Messaging` instance)
* `config.producer_configure` (allows users to fully customize the
  `WaterDrop::Producer` instance)
* `config.consumer_configure` (allows users to fully customize the
  `Karafka::App` instance)

## Producer (WaterDrop)

* No breaking changes, as we wrap it with our Kafka helpers (e.g.
  `Rimless.message` and the like — their API stayed stable)

## Consumer Setup (Karafka)

<table>
<tr>
<td valign="top">

### Karafka 2 (New)

#### Phase 1: Boot

* `bundle exec karafka server`
* Karafka: load some Karafka (server) defaults
* Karafka: require `rails` — if available
* Karafka: require `/app/karafka.rb`
* `/app/karafka.rb`: require `rimless`
* `/app/karafka.rb`: `Rimless.consumer.topics(..)`
* Rimless: `Rimless.consumer -> Rimless::Consumer::App.new` — this configures
  Karafka (including logging, code reload)
* Karafka: Karafka server takes over
  => (set up consumer groups, start listening for messages)

<br><br><br><br><br><br>

#### Phase 2: Message Consumption (batch fetching, single consumption)

* Karafka: receives message(s) on topic (synced by consumer group)
  => just one Karafka server process handles a single message, per partition
     (no double processing)
* Karafka: routes the message(s) of the topic to the Rimless "job bridge"
  consumer (`Rimless::Consumer::JobBridge`), then all messages of the batch are
  processed (lazily deserialized) and enqueued as an ActiveJob
  (`Rimless::Consumer::Job`) — while the decoded message payload is passed as
  job parameters and serialized/deserialized by ActiveJob (the job execution
  may then be concurrent via Sidekiq or another ActiveJob adapter)
  => the Kafka message now leaves the Karafka server process

* ActiveJob: `Rimless::Consumer::Job` is picked up and executed
  * Rimless: a `Rimless::Consumer::Base` child class is searched by the
    `consumer` parameter (class inside `/app/consumers`) and instantiated for
    the job context (hydrating consumer metadata, the message batch containing
    the single message, etc)
  * Rimless: `Rimless::Consumer::Base` unpacks the message `event` (e.g.
    `user_updated`) and dispatches it as a method on the child consumer with
    the remaining event parameters as arguments
  * App: `/app/consumers` class kicks in and runs business application logic
    => e.g. `IdentityApiConsumer.user_updated(user:, **_)`

</td>
<td valign="top">

### Karafka 1 (Old)

#### Phase 1: Boot

* `bundle exec karafka server`
* Karafka: load some Karafka (server) defaults
* Karafka: require `/app/karafka.rb`
* `/app/karafka.rb`: require `rimless`
* Rimless: require `railtie` — set up Sidekiq server part
* `/app/karafka.rb`: `Rimless.consumer.topics(..).boot!`
* Rimless: `Rimless.consumer -> ConsumerApp.initialize!`
  * `initialize_rails!`
  * `initialize_monitors!`
  * `initialize_karafka!`
  * `initialize_logger!`
  * `initialize_code_reload!`
* Karafka: Karafka server takes over
  => (set up consumer groups, start listening for messages)

#### Phase 2: Message Consumption (batch fetching, single consumption)

* Karafka: receives message on topic (synced by consumer group)
  => just one Karafka server process handles a single message, per partition
     (no double processing)
* Karafka: run `Rimless::Karafka::PassthroughMapper` for routing (no-op)
* Karafka: deserialize message payload with `Rimless::Karafka::AvroDeserializer`
* Karafka: decoded message is passed into `Karafka::Backends::Sidekiq`
  => (karafka-sidekiq-backend gem)
* karafka-sidekiq-backend: wrap the message payload with
  `Rimless::Karafka::Base64Interchanger`
  => (Ruby object marshalling + base64 encoding for Valkey/Redis transport,
      to overcome binary encoding issues)
  => quite high size overhead on Valkey/Redis
* karafka-sidekiq-backend: enqueue `Rimless::ConsumerJob` with the wrapped
  message payload
  => the Kafka message now leaves the Karafka server process

* Sidekiq: `Rimless::ConsumerJob` is picked up and executed
  * karafka-sidekiq-backend: a `Rimless::BaseConsumer` class is searched for
    the message (child class inside `/app/consumers`)
  * Rimless: `Rimless::BaseConsumer` unpacks the message `event` (e.g.
    `user_updated`) and dispatches it as a method on the child consumer with
    the remaining event parameters as arguments
  * App: `/app/consumers` class kicks in and runs business application logic
    => e.g. `IdentityApiConsumer.user_updated(user:, **_)`

</td>
</tr>
</table>

## Testing

See: https://github.com/karafka/karafka-testing/blob/master/2.0-Upgrade.md

* Replace `#karafka_consumer_for` in your specs with `#kafka_consumer_for`
  (provided and augmented by Rimless to skip job enqueuing and instead
  perform the wrapped consumer job directly)
* Replace `#publish_for_karafka` in your specs with `karafka.produce` (in
  case you did not use the Rimless message producing helpers)

# Upgrading from Rimless 2.x to 3.0

This guide covers all breaking changes and required migration steps when
upgrading from Rimless 2.9.x to 3.0.

## Table of Contents

- [Dependency Changes](#dependency-changes)
- [Configuration Changes](#configuration-changes)
  - [Kafka Brokers Format](#kafka-brokers-format)
  - [New Configuration Options](#new-configuration-options)
- [Consumer Setup (karafka.rb)](#consumer-setup-karafkarb)
- [Consumer Classes](#consumer-classes)
- [Application Consumer Base Class](#application-consumer-base-class)
- [Railtie / Sidekiq Server Initialization](#railtie--sidekiq-server-initialization)
- [Producer Changes](#producer-changes)
- [Testing Changes](#testing-changes)
  - [Consumer Specs](#consumer-specs)
  - [Producer Specs / Custom WaterDrop Stubs](#producer-specs--custom-waterdrop-stubs)
- [Karafka Configuration (Advanced)](#karafka-configuration-advanced)

---

## Dependency Changes

Dependency        | 2.x            | 3.0       | Upgrading Guide
------------------|----------------|-----------|----------------
`karafka`         | `~> 1.4`       | `~> 2.5`  | [Guide](https://github.com/karafka/karafka/wiki/Upgrades-Karafka-2.0)
`karafka-testing` | `~> 1.4`       | `~> 2.5`  | [Guide](https://github.com/karafka/karafka-testing/blob/master/2.0-Upgrade.md)
`waterdrop`       | `~> 1.4`       | `~> 2.8`  | [Changelog](https://github.com/karafka/waterdrop/blob/master/CHANGELOG.md)
`avro_turf`       | `~> 0.11.0`    | `~> 1.20` | [Changelog](https://github.com/dasch/avro_turf/blob/master/CHANGELOG.md)
`activejob`       | _not required_ | `>= 8.0`  | _not required_

**Removed dependencies:**

- `karafka-sidekiq-backend` — no longer used (Karafka 2 removed Sidekiq
  backend support)
- `sinatra` — no longer required for the fake schema registry in tests

The underlying Kafka driver changed from `ruby-kafka` to `librdkafka` (via
`karafka-rdkafka`). This is a native C extension — make sure your build
environment supports it.

Rimless 3.0 now depends on `activejob` (>= 8.0). If your application is a
Rails app, this is already included. For standalone apps, ensure `activejob`
is in your Gemfile.

## Configuration Changes

### Kafka Brokers Format

The `KAFKA_BROKERS` environment variable (and `config.kafka_brokers`) no longer
requires the `kafka://` protocol prefix. Plain `host:port` CSV is now expected.
The old format is still accepted for backwards compatibility, but you should
update it:

```diff
- KAFKA_BROKERS=kafka://broker1.example.com:9092,kafka://broker2.example.com:9092
+ KAFKA_BROKERS=broker1.example.com:9092,broker2.example.com:9092
```

Or in a Rails initializer:

```diff
  Rimless.configure do |conf|
-   conf.kafka_brokers = 'kafka://your.domain:9092,kafka://other.host:9092'
+   conf.kafka_brokers = 'your.domain:9092,other.host:9092'
    # Make sure it's NOT an array like ['host:port', 'host:port']
  end
```

### New Configuration Options

Rimless 3.0 adds several new configuration options. All have sensible defaults
and are **optional**:

```ruby
Rimless.configure do |conf|
  # Customize the Karafka logger listener (set to false/nil to disable)
  conf.consumer_logger_listener = Karafka::Instrumentation::LoggerListener.new(
    # Karafka, when the logger level is set to INFO, produces logs each time it
    # polls data from an internal messages queue. This can be extensive, so you
    # can turn it off by setting below to false. (Rimless defaults to false)
    log_polling: false
  )

  # Custom job bridge class (Kafka messages → ActiveJob)
  conf.job_bridge_class = Rimless::Consumer::JobBridge

  # Custom consumer job class (processes enqueued Kafka messages)
  conf.consumer_job_class = Rimless::Consumer::Job

  # Custom Apache Avro deserializer class
  conf.avro_deserializer_class = Rimless::Consumer::AvroDeserializer

  # Fully customize the AvroTurf::Messaging instance
  conf.avro_configure = ->(config) { config.merge(connect_timeout: 5) }

  # Fully customize the WaterDrop::Producer instance
  # See: https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md
  conf.producer_configure = ->(config) {
    # The number of acknowledgements the leader broker must receive from ISR
    # brokers before responding to the request
    config.kafka[:'request.required.acks'] = 1
  }

  # Fully customize the Karafka::App instance
  conf.consumer_configure = ->(config) {
    config.kafka[:'max.poll.interval.ms'] = 300_000
  }
end
```

## Consumer Setup (karafka.rb)

The `karafka.rb` boot file requires several changes:

**1. Remove `.boot!`** — Karafka 2 no longer requires an explicit boot call:

```diff
  Rimless.consumer.topics(
    { app: :your_app, name: :your_topic } => YourConsumer
- ).boot!
+ )
```

**2. Remove WaterDrop setup and listener subscriptions** — these are now
handled internally by Rimless:

```diff
# This is not needed anymore, WaterDrop now directly uses the Rimless.logger
- Karafka.monitor.subscribe(WaterDrop::Instrumentation::LoggerListener.new)

# Use the config.producer_configure instead
- monitor.subscribe('app.initialized') do
-   WaterDrop.setup { |config| config.deliver = !Karafka.env.test? }
- end
```

**3. Remove `KarafkaApp.boot!`** if present: (vanilla Karafka 1.x)

```diff
- KarafkaApp.boot!
```

**4. Update inline Karafka configuration** (if any) — Karafka 2 uses
librdkafka-style settings:

```diff
  Rimless.consumer.configure do |config|
-   config.kafka.start_from_beginning = false
-   config.kafka.heartbeat_interval = 10
+   # See: https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md
+   config.kafka[:'auto.offset.reset'] = 'latest'
  end
```

Below you can find some of the most significant naming changes in the
configuration options of Karafka 1.x to 2.x:

Root options: ([`config.*`](https://github.com/karafka/karafka/blob/v2.5.5/lib/karafka/setup/config.rb))
* `start_from_beginning` is now `initial_offset` and accepts either 'earliest'
  or 'latest'
* `ssl_ca_certs_from_system` is no longer needed, but `kafka`
  `security.protocol` needs to be set to `ssl`
* `batch_fetching` is no longer needed
* `batch_consuming` is no longer needed
* `serializer` is no longer needed because Responders have been removed from
  Karafka
* `topic_mapper` is no longer needed, as the concept of mapping topic names has
  been removed from Karafka
* `backend` is no longer needed because Karafka is now multi-threaded
* `manual_offset_management` now needs to be set on a per-topic basis

Kafka options: ([`config.kafka.*`](https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md))
* `kafka.seed_brokers` is now `bootstrap.servers` without the protocol
  definition
* `kafka.heartbeat_interval` is no longer needed
* SASL and SSL options changes are [described in their own
  section](https://github.com/karafka/karafka/wiki/Upgrades-Karafka-2.0#sasl-ssl-authentication)

See: https://github.com/karafka/karafka/wiki/Upgrades-Karafka-2.0

**Full `karafka.rb` example (after migration):**

```ruby
# frozen_string_literal: true

require 'rimless'

# Setup the topic-consumer routing table
Rimless.consumer.topics(
  { app: :your_app, name: :your_topic } => YourConsumer
)

# Optional: configure Karafka/librdkafka settings
# Rimless.consumer.configure do |config|
#   config.kafka[:'auto.offset.reset'] = 'latest'
# end
```

## Consumer Classes

All consumer-related constants have been reorganized under the
`Rimless::Consumer` namespace:

2.x Constant                         | 3.0 Constant
---                                  | ---
`Rimless::BaseConsumer`              | `Rimless::Consumer::Base`
`Rimless::ConsumerApp`               | `Rimless::Consumer::App`
`Rimless::ConsumerJob`               | `Rimless::Consumer::Job`
`Rimless::Karafka::AvroDeserializer` | `Rimless::Consumer::AvroDeserializer`

**Removed (no replacement needed):**

2.x Constant | Reason
--|---
`Rimless::Karafka::Base64Interchanger` | Messages are now decoded within the Karafka process before being passed to ActiveJob. No binary interchanging needed anymore.
`Rimless::Karafka::PassthroughMapper` | Karafka 2 removed the topic/consumer mapper concept entirely. This was previously a no-op (input equals output) for Rimless anyway.

## Application Consumer Base Class

Update your `ApplicationConsumer` (and any direct references):

```diff
- class ApplicationConsumer < Rimless::BaseConsumer
+ class ApplicationConsumer < Rimless::Consumer::Base
  end
```

The consumer API is mostly unchanged. Key differences:

- `#consume` now iterates over `#messages` (batch of one or more) instead of
  processing a single message. End-user event methods (`user_created`,
  `user_updated`, etc.) are still called once per message — this is handled
  internally.
- `#params_batch` is available as a compatibility alias for `#messages`.
- `#params` is available as a compatibility alias for `#message` (the current
  single message being processed).

## Railtie / Sidekiq Server Initialization

Rimless 2.x initialized the Karafka consumer application inside the Sidekiq
server process. This is no longer done or needed. **Remove any manual Sidekiq
server initialization:**

```diff
- Sidekiq.configure_server { Rimless.consumer.initialize! }
```

Consumer jobs are now processed via ActiveJob. Your existing ActiveJob adapter
(Sidekiq, Solid Queue, etc.) will pick them up automatically.

## Producer Changes

The public producer API (`Rimless.message`, `Rimless.async_message`,
`Rimless.raw_message`, `Rimless.async_raw_message`) is **unchanged**.

Under the hood, WaterDrop 2.x replaced `WaterDrop::SyncProducer.call` /
`WaterDrop::AsyncProducer.call` with `Rimless.producer.produce_sync` /
`Rimless.producer.produce_async`. If you were calling WaterDrop directly
(bypassing Rimless helpers), update those calls:

```diff
- WaterDrop::SyncProducer.call(encoded_data, topic: 'my.topic')
+ Rimless.producer.produce_sync(payload: encoded_data, topic: 'my.topic')

- WaterDrop::AsyncProducer.call(encoded_data, topic: 'my.topic')
+ Rimless.producer.produce_async(payload: encoded_data, topic: 'my.topic')
```

Note that WaterDrop 2.x uses keyword arguments (`payload:`, `topic:`, `key:`,
etc.) instead of positional arguments. All time-related configuration values of
WaterDrop are now in **milliseconds** (previously some were in seconds).

## Testing Changes

### Consumer Specs

**1. Replace `#karafka_consumer_for` with `#kafka_consumer_for`:**

Rimless now provides its own `#kafka_consumer_for` helper that wraps the
Karafka testing helper and automatically inlines the job bridge (so your
consumer logic executes synchronously in tests):

```diff
- let(:instance) { karafka_consumer_for(topic) }
+ let(:instance) { kafka_consumer_for(topic) }
```

**2. Replace `#publish_for_karafka` with `karafka.produce`** (if you used the
Karafka testing helpers directly):

```diff
- publish_for_karafka(message)
+ karafka.produce(message)
```

**3. Update message setup in consumer specs:**

The `kafka_message` helper now returns a proper `Karafka::Messages::Message`
instance double. Update how messages are injected:

```diff
- let(:params) { kafka_message(topic: topic, **payload) }
- before { allow(instance).to receive(:params).and_return(params) }
+ let(:message) { kafka_message(topic: topic, **payload) }
+ before { allow(instance).to receive(:messages).and_return([message]) }
```

**Full consumer spec example (after migration):**

```ruby
RSpec.describe YourConsumer do
  let(:topic) { Rimless.topic(app: :your_app, name: :your_topic) }
  let(:instance) { kafka_consumer_for(topic) }
  let(:action) { instance.consume }
  let(:message) { kafka_message(topic: topic, **payload) }

  before { allow(instance).to receive(:messages).and_return([message]) }

  context 'with user_created message' do
    let(:payload) do
      { event: :user_created, user: { name: 'John' } }
    end

    it 'processes the event' do
      # your expectations, +YourConsumer#user_created+ will be called
      action
    end
  end
end
```

### Producer Specs / Custom WaterDrop Stubs

If you had custom WaterDrop stubs in your test setup, update them:

```diff
- allow(WaterDrop::SyncProducer).to receive(:call)
- allow(WaterDrop::AsyncProducer).to receive(:call)
+ allow(Rimless.producer).to receive(:produce_sync)
+ allow(Rimless.producer).to receive(:produce_async)
```

The built-in `have_sent_kafka_message` RSpec matcher continues to work as
before — no changes needed for producer message expectations.

## Karafka Configuration (Advanced)

If you had custom Karafka configuration beyond what Rimless provides, note the
following Karafka 2 changes:

**Removed settings** (no longer applicable):

Setting | Reason
--|---
`config.backend` | Karafka 2 is multi-threaded, no Sidekiq backend
`config.batch_fetching` | Always enabled in Karafka 2
`config.batch_consuming` | Removed; tune `max_wait_time` / `max_messages`
`config.serializer` | Responders removed from Karafka
`config.topic_mapper` | Topic mapping concept removed
`config.consumer_mapper` | Consumer mapping concept removed

**Renamed settings:**

2.x | 3.0 (librdkafka)
--|---
`config.kafka.seed_brokers` | `config.kafka[:'bootstrap.servers']`
`config.start_from_beginning` | `config.kafka[:'auto.offset.reset']` (`'earliest'` or `'latest'`)
`config.kafka.heartbeat_interval` | No longer needed (handled by librdkafka)
`config.kafka.required_acks` | `config.kafka[:'request.required.acks']`

**Consumer group behavior change:** Karafka 2 builds a single consumer group
for all topics (instead of one per topic in 1.x). This is now the default and
matches Rimless conventions.

**Latency tuning:** Batch fetching is always on (just as it was configured by
Rimless in the past). To optimize for low latency or high throughput,
configure:

```ruby
Rimless.consumer.configure do |config|
  # Lower values = lower latency, higher values = higher throughput
  config.max_wait_time = 500    # ms to wait for messages (default: 1_000)
  config.max_messages = 50      # max messages per batch (default: 100)
  # Enable end-of-partition notifications if needed
  config.kafka[:'enable.partition.eof'] = true
end
```

See the [Karafka latency and throughput guide](https://karafka.io/docs/Latency-and-Throughput/)
and the [librdkafka configuration
reference](https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md)
/ [Karafka top-level
configuration](https://github.com/karafka/karafka/blob/v2.5.5/lib/karafka/setup/config.rb)
for all available options.

---

The raw research sources for this guide are located at [`doc/upgrade-guide-sources/`](./doc/upgrade-guide-sources).

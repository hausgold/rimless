![rimless](doc/assets/project.svg)

[![Continuous Integration](https://github.com/hausgold/rimless/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/hausgold/rimless/actions/workflows/test.yml)
[![Gem Version](https://badge.fury.io/rb/rimless.svg)](https://badge.fury.io/rb/rimless)
[![Test Coverage](https://automate-api.hausgold.de/v1/coverage_reports/rimless/coverage.svg)](https://knowledge.hausgold.de/coverage)
[![Test Ratio](https://automate-api.hausgold.de/v1/coverage_reports/rimless/ratio.svg)](https://knowledge.hausgold.de/coverage)
[![API docs](https://automate-api.hausgold.de/v1/coverage_reports/rimless/documentation.svg)](https://www.rubydoc.info/gems/rimless)

This project is dedicated to ship a ready to use [Apache
Kafka](https://kafka.apache.org/) / [Confluent Schema
Registry](https://docs.confluent.io/current/schema-registry/index.html) /
[Apache Avro](https://avro.apache.org/) message producing toolset by making use
of the [WaterDrop](https://rubygems.org/gems/waterdrop) and
[AvroTurf](https://rubygems.org/gems/avro_turf) gems. It comes as an
opinionated framework which sets up solid conventions for producing messages.

- [Installation](#installation)
- [Usage](#usage)
  - [Configuration](#configuration)
    - [Available environment variables](#available-environment-variables)
  - [Conventions](#conventions)
    - [Apache Kafka Topic](#apache-kafka-topic)
    - [Confluent Schema Registry Subject](#confluent-schema-registry-subject)
  - [Organize and write schema definitions](#organize-and-write-schema-definitions)
  - [Producing messages](#producing-messages)
  - [Consuming messages](#consuming-messages)
    - [Routing messages to consumers](#routing-messages-to-consumers)
    - [Consuming event messages](#consuming-event-messages)
    - [Listing consumer routes](#listing-consumer-routes)
    - [Starting the consumer process(es)](#starting-the-consumer-processes)
  - [Encoding/Decoding messages](#encodingdecoding-messages)
    - [Handling of schemaless deep blobs](#handling-of-schemaless-deep-blobs)
  - [Writing tests for your messages](#writing-tests-for-your-messages)
- [Development](#development)
- [Contributing](#contributing)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rimless'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install rimless
```

## Usage

### Configuration

You can configure the rimless gem via an Rails initializer, by environment
variables or on demand. Here we show a common Rails initializer example:

```ruby
Rimless.configure do |conf|
  # Defaults to +Rails.env+ when available
  conf.env = 'test'
  # Defaults to your Rails application name when available
  conf.app_name = 'your-app'
  # Dito
  conf.client_id = 'your-app'

  # Writes to stdout by default
  conf.logger = Logger.new(IO::NULL)

  # Defaults to the default Rails configuration directory,
  # or the current working directory plus +avro_schemas+
  conf.avro_schema_path = 'config/avro_schemas'
  conf.compiled_avro_schema_path = 'config/avro_schemas/compiled'

  # The list of Apache Kafka brokers for cluster discovery,
  # set to HAUSGOLD defaults when not set
  conf.kafka_brokers = 'kafka://your.domain:9092,kafka..'

  # The Confluent Schema Registry API URL,
  # set to HAUSGOLD defaults when not set
  conf.schema_registry_url = 'http://your.schema-registry.local'

  # The Sidekiq job queue to use for consuming jobs
  config.consumer_job_queue = 'default'
end
```

The rimless gem comes with sensitive defaults as you can see. For most users an
extra configuration is not needed.

#### Available environment variables

The rimless gem can be configured hardly with its configuration code block like
shown before. Respecting the [twelve-factor app](https://12factor.net/)
concerns, the gem allows you to set almost all configurations (just the
relevant ones for runtime) via environment variables. Here comes a list of
available configuration options:

* **KAFKA_ENV**: The application environment. Falls back to `Rails.env` when available.
* **KAFKA_CLIENT_ID**: The Apache Kafka client identifier, falls back the the local application name.
* **KAFKA_BROKERS**: A comma separated list of Apache Kafka brokers for cluster discovery (Plaintext, no-auth/no-SSL only for now) (eg. `kafka://your.domain:9092,kafka..`)
* **KAFKA_SCHEMA_REGISTRY_URL**: The Confluent Schema Registry API URL to use for schema registrations.
* **KAFKA_SIDEKIQ_JOB_QUEUE**: The Sidekiq job queue to use for consuming jobs. Falls back to `default`.

### Conventions

#### Apache Kafka Topic

The topic name on Kafka is prefixed with the
application environment and application name. This allows the usage of a single
Apache Kafka cluster for multiple application environments (eg. canary and
production). The application name on the topic allows direct knowledge of the
message origin. Convention rules:

* Schema is `<ENV>.<APP>.<CONCERN>`
* All components are lowercase and in [kebab-case](http://bit.ly/2IoQZiv) form

Here comes a Kafka topic name example: `production.identity-api.users`

#### Confluent Schema Registry Subject

Each subject (schema) is versioned and named for reference on the Schema
Registry. The subject naming convention is mostly the same as the Apache Kafka
Topic convention, except the allowed characters. [Apache
Avro](https://avro.apache.org/docs/1.8.2/spec.html#namespace) just allows
`[A-Za-z0-9_]` and no numbers on the first char. The application environment
prefix allows the usage of the very same Schema Registry instance for multipe
environments and the application name just reflects the schema origin.
Convention rules:

* Schema is `<ENV>.<APP>.<ENTITY>`
* All components are lowercase and in [snake_case](http://bit.ly/2IoQZiv) form

Here comes a subject name example: `production.identity_api.user_v1`

**Gotcha**: Why is this `user_v1` when the Schema Registry is tracking the
subject versions all by itself? At HAUSGOLD we stick to our API definition
versions of our entity representations. So a users v1 API looks like the
`user_v1` schema definition, this eases interoperability. The rimless gem does
not force you to do so as well.

### Organize and write schema definitions

Just because you want to produce messages with rimless, it comes to the point
that you need to [define your data
schemas](https://avro.apache.org/docs/1.8.2/spec.html). The rimless gem
supports you with some good conventions, automatic compilation of Apache Avro
schema [ERB
templates](https://ruby-doc.org/stdlib-2.6.2/libdoc/erb/rdoc/ERB.html) and
painless JSON validation of them.

First things first, by convention the rimless gem looks for Apache Avro schema
ERB templates on the `$(pwd)/config/avro_schemas` directory. Nothing special
from the Rails perspective. You can also reconfigure the file locations, just
[see the configuration
block](https://github.com/hausgold/rimless/blob/master/lib/rimless/configuration.rb#L36).

Each schema template MUST end with the `.avsc.erb` extension to be picked up,
even in recursive directory structures.  You can make use of the ERB templating
or not, but rimless just looks for these templates. When it comes to
structuring the Avro Schemas it is important that the file path reflects the
embeded schema namespace correctly. So when `$(pwd)/config/avro_schemas` is our
schema namespace root, then the `production.identity_api.user_v1` schema
converts to the
`$(pwd)/config/avro_schemas/compiled/production/identity_api/user_v1.avsc`
file path for Apache Avro.

The corresponding Avro Schema template is located at
`$(pwd)/config/avro_schemas/identity_api/user_v1.avsc.erb`. Now it's going to
be fancy. The automatic schema compiler picks up the dynamically/runtime set
namespace from the schema definition and converts it to its respective
directory structure. So when you boot your application container/instance
inside your *canary*  environment, the schemas/messages should reflect this so
they do not mix with other environments.

Example time. **$(pwd)/config/avro_schemas/identity_api/user_v1.avsc.erb**:

```json
{
  "name": "user_v1",
  "namespace": "<%= namespace %>",
  "type": "record",
  "fields": [
    {
      "name": "firstname",
      "type": "string"
    },
    {
      "name": "lastname",
      "type": "string"
    },
    {
      "name": "address",
      "type": "<%= namespace %>.address_v1"
    },
    {
      "name": "metadata",
      "doc": "Watch out for schemaless deep hash blobs. (+.avro_schemaless_h+)",
      "type": {
        "type": "map",
        "values": "string"
      }
    }
  ]
}
```

**$(pwd)/config/avro_schemas/identity_api/address_v1.avsc.erb**:

```json
{
  "name": "address_v1",
  "namespace": "<%= namespace %>",
  "type": "record",
  "fields": [
    {
      "name": "street",
      "type": "string"
    }
    {
      "name": "city",
      "type": "string"
    }
  ]
}
```

The compiled Avro Schemas are written to the
`$(pwd)/config/avro_schemas/compiled/` directory by default. You can
[reconfigure the
location](https://github.com/hausgold/rimless/blob/master/lib/rimless/configuration.rb#L44)
if needed. For VCS systems like Git it is useful to create an relative ignore
list at `$(pwd)/config/avro_schemas/.gitignore` with the following contents:

```gitignore
compiled/
```

### Producing messages

Under the hood the rimless gem makes use of the [WaterDrop
gem](https://rubygems.org/gems/waterdrop) to send messages to the Apache Kafka
cluster. But with the addition to send Apache Avro encoded messages with a
single call. Here comes some examples how to use it:

```ruby
metadata = { hobbies: %w(dancing singing sports) }
address = { street: 'Bahnhofstraße 5-6', city: '12305 Berlin' }
user = { firstname: 'John', lastname: 'Doe',
         address: address, metadata: Rimless.avro_schemaless_h(metadata) }

# Encode and send the message to a Kafka topic (sync, blocking)
Rimless.message(data: user, schema: :user_v1, topic: :users)
# schema is relative resolved to: +development.identity_api.user_v1+
# topic is relative resolved to: +development.identity-api.users+

# You can also make use of an asynchronous message sending
Rimless.async_message(data: user, schema: :user_v1, topic: :users)

# In cases you just want the encoded Apache Avro binary blob, you can encode it
# directly with our simple helper like this:
encoded = Rimless.encode(user, schema: 'user_v1')
# Next to this wrapped shortcut (see Encoding/Decoding messages section for
# details), we provide access to our configured AvroTurf gem instance via
# +Rimless.avro+, so you can also use +Rimless.avro.encode(user, ..)+

# You can also send raw messages with the rimless gem, so encoding of your
# message must be done before
Rimless.raw_message(data: encoded, topic: :users)
# topic is relative resolved to: +development.identity-api.users+

# In case you want to send messages to a non-local application topic you can
# specify the application, too. This allows you to send a message to the
# +<ENV>.address-api.addresses+ from you local identity-api.
Rimless.raw_message(data: encoded, topic: { name: :users, app: 'address-api' })
# Also works with the Apache Avro encoding variant
Rimless.message(data: user, schema: :user_v1,
                topic: { name: :users, app: 'address-api' })

# And for the sake of completeness, you can also send raw
# messages asynchronously
Rimless.async_raw_message(data: encoded, topic: :users)
```

### Consuming messages

The rimless gem makes it super easy to build consumer logic right into your
(Rails, standalone) application by utilizing the [Karafka
framework](https://github.com/karafka/karafka) under the hood. When you have
the rimless gem already installed you are ready to rumble to setup your
application to consume Apache Kafka messages. Just run the `$ rake
rimless:install` and all the consuming setup is done for you.

Afterwards you find the `karafka.rb` file at the root of your project together
with an example consumer (including specs). The default configuration follows
the base conventions and ships some opinions on the architecture. The
architecture looks like this:

```
              +----[Apache Kafka]
              |
     fetch message batches
              |
              v
  +-----------------------------+
  | Karafka/Rimless Consumer    |    +--------------------------------------+
  |   Shares a single consumer  |--->| Sidekiq                              |
  |   group, multiple processes |    |   Runs the consumer class (children  |
  +-----------------------------+    |   of Rimless::BaseConsumer) for each |
                                     |   message (Rimless::ConsumerJob),    |
                                     |   one message per job                |
                                     +--------------------------------------+
```

This architecture allows the consumer process to run mostly non-blocking and
the messages can be processed concurrently via Sidekiq. (including the error
handling and retrying)

#### Routing messages to consumers

The `karafka.rb` file at the root of your project is dedicated to configure the
consumer process, including the routing table. The routing is as easy as it
gets by following this pattern: `topic => consumer`. Here comes a the full
examples:

```ruby
# Setup the topic-consumer routing table and boot the consumer application
Rimless.consumer.topics(
  { app: :your_app, name: :your_topic } => CustomConsumer
).boot!
```

The key side of the hash is anything which is understood by the `Rimless.topic`
method. With one addition: you can change `:name` to `:names` and pass an array
of strings or symbols to listen to multiple application topics with a single
configuration line.

```ruby
Rimless.consumer.topics(
  { app: :your_app, names: %i[a b c] } => CustomConsumer
).boot!

# is identical to:

Rimless.consumer.topics(
  { app: :your_app, name: :a } => CustomConsumer,
  { app: :your_app, name: :b } => CustomConsumer,
  { app: :your_app, name: :c } => CustomConsumer
).boot!
```

#### Consuming event messages

By convention it makes sense to produce messages with various event types on a
single Apache Kafka topic. This is fine, they just must follow a single
constrain: each message must contain an `event`-named field at the Apache Avro
schema with a dedicated name. This allow to structure data at Kafka like this:

```
Topic: production.users-api.users
Events: user_created, user_updated, user_deleted
```

While respecting this convention your consumer classes will be super clean. See
the following example: (we keep the users api example)

```ruby
class UserApiConsumer < ApplicationConsumer
  def user_created(schema_field1:, optional_schema_field2: nil)
    # Do whatever you need when a user was created
  end
end
```

Just name a method like the name of the event and specify all Apache Avro
schema fields of it, except the event field. The messages will be automatically
decoded with the help of the schema registry. All hashes/arrays ship deeply
symbolized keys for easy access.

**Heads up!** All messages with events which are not reflected by a method will
just be ignored.

See the automatically generated spec (`spec/consumers/custom_consumer_spec.rb`)
for an example on how to test this.

#### Listing consumer routes

The rimless gem ships a simple tool to view all your consumer routes and the
event messages it reacts on. Just run:

```shell
# Print all Apache Kafka consumer routes
$ rake rimless:routes

#    Topic: users-api.users
# Consumer: UserApiConsumer
#   Events: user_created
```

#### Starting the consumer process(es)

From system integration perspective you just need to start the consumer
processes and Sidekiq to get the thing going. Rimless allows you to start the
consumer with `$ rake rimless:consumer` or you can just use the [Karafka
binary](https://github.com/karafka/karafka/wiki/Fetching-messages) to start the
consumer (`$ bundle exec karafka server`). Both work identically.

When running inside a Rails application the consumer application initialization
is automatically done for Sidekiq. Otherwise you need to initialize the
consumer application manually with:

```ruby
# Manual consumer application initialization
Sidekiq.configure_server { Rimless.consumer.initialize! }
```

### Encoding/Decoding messages

By convention we focus on the [Apache Avro](https://avro.apache.org/) data
format. This is provided by the [AvroTurf](https://rubygems.org/gems/avro_turf)
gem and the rimless gem adds some neat helpers on top of it. Here are a few
examples to show how rimless can be used to encode/decode Apache Avro data:

```ruby
# Encode a data structure (no matter of symbolized, or stringified keys, or
# non-simple types) to Apache Avro format
encoded = Rimless.encode(user, schema: 'user_v1')

# Works the same for symbolized schema names
encoded = Rimless.encode(user, schema: :user_v1)

# Also supports the resolution of deep relative schemes
# (+.user.address+ becomes +<ENV>.<APP>.user.address+)
encoded = Rimless.encode(user.address, schema: '.user.address')

# Decoding Apache Avro data is even more simple. The resulting data structure
# is deeply key-symbolized.
decoded = Rimless.decode('your-avro-binary-data-here')
```

#### Handling of schemaless deep blobs

Apache Avro is by design a strict, type casted format which does not allow
undefined mix and matching of deep structures. This is fine because it forces
the producer to think twice about the schema definition. But sometimes there is
unstructured data inside of entities. Think of a metadata hash on a user entity
were the user (eg. a frontend client) just can add whatever comes to his mind
for later processing. Its not searchable, its never touched by the backend, but
its present.

Thats a case we're experienced and kind of solved on the rimless gem. You can
make use of the `Rimless.avro_schemaless_h` method to [sparsify the data
recursively](https://github.com/simplymeasured/sparsify). Say you have the
following metadata hash:

```ruby
metadata = {
  test: true,
  hobbies: %w(writing cooking moshpit),
  a: {
    b: [
      { c: true },
      { d: false }
    ]
  }
}
```

It's messy, by design. From the Apache Avro perspective you just can define a
map. The map keys are assumed to be strings - and the most hitting value data
type is a string, too. Thats where hash sparsification comes in. The resulting
metadata hash looks like this and can be encoded by Apache Avro:

```ruby
Rimless.avro_schemaless_h(metadata)
# => {
#      "test"=>"true",
#      "hobbies.0"=>"writing",
#      "hobbies.1"=>"cooking",
#      "hobbies.2"=>"moshpit",
#      "a.b.0.c"=>"true",
#      "a.b.1.d"=>"false"
#    }
```

With the help of the [sparsify gem](https://rubygems.org/gems/sparsify) you can
also revert this to its original form. But with the loss of data type
correctness. Another approach can be used for these kind of scenarios: encoding
the schemaless data with JSON and just set the metadata field on the Apache
Avro schema to be a string. Choice is yours.

### Writing tests for your messages

Producing messages is a bliss with the rimless gem, but producing code needs to
be tested as well. Thats why the gem ships some RSpec helpers and matchers for
this purpose. A common situation is also handled by the RSpec extension: on the
test environment (eg. a continuous integration service) its not likely to have
a Apache Kafka/Confluent Schema Registry cluster available. Thats why actual
calls to Kafka/Schema Registry are mocked away.

First of all, just add `require 'rimless/rspec'` to your `spec_helper.rb` or
`rails_helper.rb`.

The `#avro_parse` helper is just in place to decode Apache Avro binary blobs to
their respective Ruby representations, in case you have to handle content
checks. Here comes an example:

```ruby
describe 'message content' do
  let(:message) { file_fixture('user_v1_avro.bin').read }

  it 'contains the firstname' do
    expect(avro_parse(message)).to include(firstname: 'John')
  end
end
```

Nothing special, not really fancy. A more complex situation occurs when you
separate your Kafka message producing logic inside an asynchronous job (eg.
Sidekiq or ActiveJob). Therefore is the `have_sent_kafka_message` matcher
available. Example time:

```ruby
describe 'message producer job' do
  let(:user) { create(:user) } # FactoryBot FTW
  let(:action) { SendUserCreatedMessageJob.perform_now(user) }

  it 'encodes the message with the correct schema' do
    expect { action }.to have_sent_kafka_message('test.identity_api.user_v1')
    #                                the schema name --^
  end

  it 'sends a single message' do
    expect { action }.to have_sent_kafka_message.exactly(1)
    # Also available: (known from rspec-rails ActiveJob matcher)
    #   .at_least(2).times
    #   .at_most(3).times
    #   .exactly(:twice)
    #   .once
  end

  it 'sends the message to the correct topic' do
    expect { action }.to \
      have_sent_kafka_message.with(topic: 'test.identity-api.users')
  end

  it 'sends a message key' do
    # Rimless.message(data: user, schema: :user_v1, topic: :users,
    #                 key: user.id, partition: 1) # <-- additional Kafka metas
    # @see https://github.com/karafka/waterdrop#usage for all options
    expect { action }.to \
      have_sent_kafka_message.with(key: String, topic: anything)
    #                 mind the order --^
    #                 its a argument list validation, all keys must be named
  end

  it 'sends the correct user data' do
    expect { action }.to have_sent_kafka_message.with_data(firstname: 'John')
    #                    deep hash including the given keys? --^
  end

  it 'sends no message (when not called)' do
    expect { nil }.not_to have_sent_kafka_message
  end

  it 'allows complex expactations' do
    expect { action; action }.to \
      have_sent_kafka_message('test.identity_api.user_v1')
        .with(key: user.id, topic: 'test.identity-api.users').twice
        .with_data(firstname: 'John', lastname: 'Doe').twice
  end

  it 'allows to capture messages to check them in detail' do
    (capture_kafka_messages { action }).tap do |messages|
      expect(messages.first[:data]).to \
        match(a_hash_including('entity' => a_hash_including('items' => items)))
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bundle exec rake spec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/hausgold/rimless.

### next

* Raised minimum supported Ruby/Rails version to 2.7/6.1 (#45)

### 1.8.0 (14 November 2024)

* Added support for custom topic names via the `full_name:` keyword argument on
  the consumer routing table (#44)
* Added support to pass a block to the routing table
  (`Rimless.consumer.topics`) to add custom topic configurations (#44)

### 1.7.7 (19 September 2024)

* Corrected the Sidekiq interchanger decoding, which is caused by an upstream
  update of the karafka-sidekiq-backend gem (#43)

### 1.7.6 (19 September 2024)

* Added a monkey-patch for the constellation Karafka 1.4 and Thor 1.3,
  on Ruby >=2.7 (#42)

### 1.7.5 (15 August 2024)

* Just a retag of 1.7.1

### 1.7.4 (15 August 2024)

* Just a retag of 1.7.1

### 1.7.3 (15 August 2024)

* Just a retag of 1.7.1

### 1.7.2 (9 August 2024)

* Just a retag of 1.7.1

### 1.7.1 (9 August 2024)

* Added API docs building to continuous integration (#41)

### 1.7.0 (8 July 2024)

* Added CI tests for Rails 6.1 and 7.1 (#39)

### 1.6.0 (3 July 2024)

* Dropped support for Ruby <2.7 (#38)
* Moved the schema file validation into the retry block for parallel execution
  (#37)
* Updated the [Kafka Playground](./doc/kafka-playground) to the latest
  Apache Kafka (3.7) and Schema Registry (7.6) versions (#35)

### 1.5.1 (26 April 2024)

* Added a retry to write compiled schema files as this may fail on parallel
  execution (#33)

### 1.5.0 (4 December 2023)

* Do not extend the `Rimless.logger` to write to stdout by default when running
  in the `development` environment - this generates duplicated messages when
  the configured logger already writes to stdout. A new configuration was added
  `Rimless.configuration.extend_dev_logger = false` was added (#32)

### 1.4.2 (12 July 2023)

* Reverted to use `yield_self` instead of `then` in order to support Ruby 2.5
  as advertised (broken since #19, 1.3.0) (#31)

### 1.4.1 (5 July 2023)

* Moved the development dependencies from the gemspec to the Gemfile (#29)
* Pinned Karafka gem <1.4.15 in order to suppress the
  `I_ACCEPT_CRITICAL_ERRORS_IN_KARAFKA_1_4=true` agony (#30)

### 1.4.0 (24 February 2023)

* Added support for Gem release automation

### 1.3.0 (18 January 2023)

* Bundler >= 2.3 is from now on required as minimal version (#19)
* Dropped support for Ruby < 2.5 (#19)
* Dropped support for Rails < 5.2 (#19)
* Updated all development/runtime gems to their latest
  Ruby 2.5 compatible version (#19)

### 1.2.0 (4 October 2021)

* Added a `capture_kafka_messages` helper for RSpec (#12)

### 1.1.1 (12 May 2021)

* Corrected the GNU Make release target

### 1.1.0 (23 October 2020)

* Added support for Karafka `~> 1.4.0` and set is as minimum dependency version
  (#10)

### 1.0.4 (14 August 2020)

* Mocked WaterDrop producers in the rimless rspec helper so that tests
  won't actually talk to Kafka (#9)

### 1.0.3 (14 May 2020)

* Corrected broken stats when no consumer is yet defined (#8)

### 1.0.2 (11 March 2020)

* Only load the statistics rake task when Rails is available and the
  environment is development (instead of not production, this may cause issues
  for +canary+ or +stage+ Rails environments)

### 1.0.1 (11 March 2020)

* Added the missing +Karafka::Testing::RSpec::Helpers+ include to the
  RSpec configuration

### 1.0.0 (11 March 2020)

* Dropped support for Ruby 2.3/2.4 and added support for Rails 6.0 (#6)
* Implemented a simple opinionated Kafka consumer setup (#7)

### 0.3.0 (8 November 2019)

* Upgraded the avro_turf gem (`~> 0.11.0`) (#5)

### 0.2.1 (13 August 2019)

* Added support for the
  [parallel_tests](https://github.com/grosser/parallel_tests) gem and
  reconfigure the compiled schema directory to be unique per running test
  thread.  This fixes all race conditions which slow down or break user test
  suites.

### 0.2.0 (5 June 2019)

* Added the `Rimless.encode` (`.avro_encode`) and `Rimless.decode`
  (`.avro_decode`) helpers/shortcuts to simplify the interaction with the
  Apache Avro library
  * The `.encode` method automatically performs input data sanitation and
    supports deep relative (to the local namespace) schema resolution. This
    allows you to access deeply located schemes relative by just providing a
    leading period (eg. `.deep.a.b.c` becomes
    `development.your_app.deep.a.b.c`)
* The `.message`, '.sync_message', '.async_message' helpers now make use of the
  new `.encode` functionality which adds transparent data sanitation and schema
  name features
* At the `test` environment the compiled Avro schemas output path is not
  deleted anymore, instead the compiled schemas are overwritten. This may keep
  dead schemas, but it allows parallel test execution without flaws. The removal
  of the compiled schema directory caused previously file read errors when a
  parallel process started a recompilation.

### 0.1.4 (17 April 2019)

* Reconfigure (reset) the AvroTurf instance on tests to avoid caching issues
  (on failed tests the message decoding was not working which results in
  unrelated errors, instead of showing the actual test failure)

### 0.1.3 (16 April 2019)

* Check for unset and empty values while configuring dependencies

### 0.1.2 (16 April 2019)

* Skip the configuration of the AvroTurf gem in case no schema registry URL is
  configured, this allows the smooth run of Rails asset precompilations without
  full environment configurations (eg. on CI)

### 0.1.1 (16 April 2019)

* Skip the configuration of the WaterDrop gem in case no brokers are
  configured, this allows the smooth run of Rails asset precompilations without
  full environment configurations (eg. on CI)

### 0.1.0 (16 April 2019)

* The first release with support for simple Apache Avro message producing on
  Apache Kafka/Confluent Schema Registry
* Improved the automatic Avro Schema ERB template compiling and included a JSON
  validation for each file
* Added a powerful RSpec helper/matcher to ease message producer logic tests
* Added an extensive documentation

### next

* Migrated to hausgold/actions@v2 (#65)

### 2.3.0 (26 December 2025)

* Added Ruby 4.0 support ([#64](https://github.com/hausgold/rimless/pull/64))
* Dropped Ruby 3.2 and Rails 7.1 support ([#63](https://github.com/hausgold/rimless/pull/63))

### 2.2.0 (19 December 2025)

* Migrated to a shared Rubocop configuration for HAUSGOLD gems ([#62](https://github.com/hausgold/rimless/pull/62))

### 2.1.0 (23 October 2025)

* Added support for Rails 8.1 ([#60](https://github.com/hausgold/rimless/pull/60))
* Switched from `ActiveSupport::Configurable` to a custom implementation based
  on `ActiveSupport::OrderedOptions` ([#61](https://github.com/hausgold/rimless/pull/61))

### 2.0.0 (28 June 2025)

* Corrected some RuboCop glitches ([#58](https://github.com/hausgold/rimless/pull/58))
* Drop Ruby 2 and end of life Rails (<7.1) ([#59](https://github.com/hausgold/rimless/pull/59))

### 1.13.3 (21 May 2025)

* Corrected some RuboCop glitches ([#56](https://github.com/hausgold/rimless/pull/56))
* Added a workaround for broken specs when Sidekiq >=8.0.3 is installed ([#57](https://github.com/hausgold/rimless/pull/57))

### 1.13.2 (11 March 2025)

* Corrected a typo of #54, its `rimless/railtie` not `rimless/rails` ([#55](https://github.com/hausgold/rimless/pull/55))

### 1.13.1 (11 March 2025)

* Upgraded the rubocop dependencies ([#53](https://github.com/hausgold/rimless/pull/53))
* Make sure to load 'rimless/railtie' when we initialize Rails on the consumer
  application ([#54](https://github.com/hausgold/rimless/pull/54))

### 1.13.0 (27 February 2025)

* Added support for Sidekiq 7 in conjunction with Rails ([#52](https://github.com/hausgold/rimless/pull/52))

### 1.12.0 (27 February 2025)

* Corrected some RuboCop glitches ([#50](https://github.com/hausgold/rimless/pull/50))
* Relaxed the sinatra gem dependency to >= 2.0 ([#51](https://github.com/hausgold/rimless/pull/51))

### 1.11.0 (30 January 2025)

* Added all versions up to Ruby 3.4 to the CI matrix ([#49](https://github.com/hausgold/rimless/pull/49))

### 1.10.2 (17 January 2025)

* Added the logger dependency ([#48](https://github.com/hausgold/rimless/pull/48))

### 1.10.1 (13 January 2025)

* Do not eager load the configuration ([#47](https://github.com/hausgold/rimless/pull/47))

### 1.10.0 (11 January 2025)

* Switched to Zeitwerk as autoloader ([#46](https://github.com/hausgold/rimless/pull/46))

### 1.9.0 (3 January 2025)

* Raised minimum supported Ruby/Rails version to 2.7/6.1 ([#45](https://github.com/hausgold/rimless/pull/45))

### 1.8.0 (14 November 2024)

* Added support for custom topic names via the `full_name:` keyword argument on
  the consumer routing table ([#44](https://github.com/hausgold/rimless/pull/44))
* Added support to pass a block to the routing table
  (`Rimless.consumer.topics`) to add custom topic configurations ([#44](https://github.com/hausgold/rimless/pull/44))

### 1.7.7 (19 September 2024)

* Corrected the Sidekiq interchanger decoding, which is caused by an upstream
  update of the karafka-sidekiq-backend gem ([#43](https://github.com/hausgold/rimless/pull/43))

### 1.7.6 (19 September 2024)

* Added a monkey-patch for the constellation Karafka 1.4 and Thor 1.3,
  on Ruby >=2.7 ([#42](https://github.com/hausgold/rimless/pull/42))

### 1.7.5 (15 August 2024)

* Just a retag of 1.7.1

### 1.7.4 (15 August 2024)

* Just a retag of 1.7.1

### 1.7.3 (15 August 2024)

* Just a retag of 1.7.1

### 1.7.2 (9 August 2024)

* Just a retag of 1.7.1

### 1.7.1 (9 August 2024)

* Added API docs building to continuous integration ([#41](https://github.com/hausgold/rimless/pull/41))

### 1.7.0 (8 July 2024)

* Added CI tests for Rails 6.1 and 7.1 ([#39](https://github.com/hausgold/rimless/pull/39))

### 1.6.0 (3 July 2024)

* Dropped support for Ruby <2.7 ([#38](https://github.com/hausgold/rimless/pull/38))
* Moved the schema file validation into the retry block for parallel execution
  ([#37](https://github.com/hausgold/rimless/pull/37))
* Updated the [Kafka Playground](./doc/kafka-playground) to the latest
  Apache Kafka (3.7) and Schema Registry (7.6) versions ([#35](https://github.com/hausgold/rimless/pull/35))

### 1.5.1 (26 April 2024)

* Added a retry to write compiled schema files as this may fail on parallel
  execution ([#33](https://github.com/hausgold/rimless/pull/33))

### 1.5.0 (4 December 2023)

* Do not extend the `Rimless.logger` to write to stdout by default when running
  in the `development` environment - this generates duplicated messages when
  the configured logger already writes to stdout. A new configuration was added
  `Rimless.configuration.extend_dev_logger = false` was added ([#32](https://github.com/hausgold/rimless/pull/32))

### 1.4.2 (12 July 2023)

* Reverted to use `yield_self` instead of `then` in order to support Ruby 2.5
  as advertised (broken since #19, 1.3.0) ([#31](https://github.com/hausgold/rimless/pull/31))

### 1.4.1 (5 July 2023)

* Moved the development dependencies from the gemspec to the Gemfile ([#29](https://github.com/hausgold/rimless/pull/29))
* Pinned Karafka gem <1.4.15 in order to suppress the
  `I_ACCEPT_CRITICAL_ERRORS_IN_KARAFKA_1_4=true` agony ([#30](https://github.com/hausgold/rimless/pull/30))

### 1.4.0 (24 February 2023)

* Added support for Gem release automation

### 1.3.0 (18 January 2023)

* Bundler >= 2.3 is from now on required as minimal version ([#19](https://github.com/hausgold/rimless/pull/19))
* Dropped support for Ruby < 2.5 ([#19](https://github.com/hausgold/rimless/pull/19))
* Dropped support for Rails < 5.2 ([#19](https://github.com/hausgold/rimless/pull/19))
* Updated all development/runtime gems to their latest
  Ruby 2.5 compatible version ([#19](https://github.com/hausgold/rimless/pull/19))

### 1.2.0 (4 October 2021)

* Added a `capture_kafka_messages` helper for RSpec ([#12](https://github.com/hausgold/rimless/pull/12))

### 1.1.1 (12 May 2021)

* Corrected the GNU Make release target

### 1.1.0 (23 October 2020)

* Added support for Karafka `~> 1.4.0` and set is as minimum dependency version
  ([#10](https://github.com/hausgold/rimless/pull/10))

### 1.0.4 (14 August 2020)

* Mocked WaterDrop producers in the rimless rspec helper so that tests
  won't actually talk to Kafka ([#9](https://github.com/hausgold/rimless/pull/9))

### 1.0.3 (14 May 2020)

* Corrected broken stats when no consumer is yet defined ([#8](https://github.com/hausgold/rimless/pull/8))

### 1.0.2 (11 March 2020)

* Only load the statistics rake task when Rails is available and the
  environment is development (instead of not production, this may cause issues
  for +canary+ or +stage+ Rails environments)

### 1.0.1 (11 March 2020)

* Added the missing +Karafka::Testing::RSpec::Helpers+ include to the
  RSpec configuration

### 1.0.0 (11 March 2020)

* Dropped support for Ruby 2.3/2.4 and added support for Rails 6.0 ([#6](https://github.com/hausgold/rimless/pull/6))
* Implemented a simple opinionated Kafka consumer setup ([#7](https://github.com/hausgold/rimless/pull/7))

### 0.3.0 (8 November 2019)

* Upgraded the avro_turf gem (`~> 0.11.0`) ([#5](https://github.com/hausgold/rimless/pull/5))

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

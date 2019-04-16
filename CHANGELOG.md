### 0.1.2

* Skip the configuration of the AvroTurf gem in case no schema registry URL is
  configured, this allows the smooth run of Rails asset precompilations without
  full environment configurations (eg. on CI)

### 0.1.1

* Skip the configuration of the WaterDrop gem in case no brokers are
  configured, this allows the smooth run of Rails asset precompilations without
  full environment configurations (eg. on CI)

### 0.1.0

* The first release with support for simple Apache Avro message producing on
  Apache Kafka/Confluent Schema Registry
* Improved the automatic Avro Schema ERB template compiling and included a JSON
  validation for each file
* Added a powerful RSpec helper/matcher to ease message producer logic tests
* Added an extensive documentation

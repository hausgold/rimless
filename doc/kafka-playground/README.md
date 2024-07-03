![Apache Kafka Playground](doc/assets/project.svg)

This sub-project is dedicated to allow a simple local bootstrap of the Apache
Kafka ecosystem with the help of containers/Docker. **Heads up!** This
configuration is not designed to be used in production.

- [Requirements](#requirements)
- [Getting started](#getting-started)
- [What's in the box](#whats-in-the-box)
- [Examples](#examples)
  - [Simple Message Producing/Consuming](#simple-message-producingconsuming)
  - [Message Producing/Consuming with Rimless (Apache Avro)](#message-producingconsuming-with-rimless-apache-avro)

## Requirements

* [GNU Make](https://www.gnu.org/software/make/) (>=4.2.1)
* [Docker](https://www.docker.com/get-docker) (>=17.06.0-ce)
* [Docker Compose](https://docs.docker.com/compose/install/) (>=1.15.0)
* [Host enabled mDNS stack](#mdns-host-configuration)

## Getting started

First you need to clone this repository from Github:

```bash
# Clone the repository
$ git clone git@github.com:hausgold/rimless.git
# Go in the repository directory
$ cd rimless/doc/kafka-playground
```

We assume you have prepared the requirements in advance. The only thing
which is left, is to install and start the application:

```shell
$ make install
$ make start
```

## mDNS host configuration

If you running Ubuntu/Debian, all required packages should be in place out of
the box. On older versions (Ubuntu < 18.10, Debian < 10) the configuration is
also fine out of the box. When you however find yourself unable to resolve the
domains or if you are a lucky user of newer Ubuntu/Debian versions, read on.

**Heads up:** This is the Arch Linux way. (package and service names may
differ, config is the same) Install the `nss-mdns` and `avahi` packages, enable
and start the `avahi-daemon.service`. Then, edit the file `/etc/nsswitch.conf`
and change the hosts line like this:

```bash
hosts: ... mdns4 [NOTFOUND=return] resolve [!UNAVAIL=return] dns ...
```

Afterwards create (or overwrite) the `/etc/mdns.allow` file when not yet
present with the following content:

```bash
.local.
.local
```

This is the regular way for nss-mdns > 0.10 package versions (the
default now). If you use a system with 0.10 or lower take care of using
`mdns4_minimal` instead of `mdns4` on the `/etc/nsswitch.conf` file and skip
the creation of the `/etc/mdns.allow` file.

**Further readings**
* Archlinux howto: https://wiki.archlinux.org/index.php/avahi
* Ubuntu/Debian howto: https://wiki.ubuntuusers.de/Avahi/
* Further detail on nss-mdns: https://github.com/lathiat/nss-mdns

## What's in the box

After the installation and bootup processes are finished you should have a
working Apache Kafka setup which includes the following:

* A single node [Apache Kafka](https://kafka.apache.org/) (without Zookeeper,
  KRaft) broker
* [Confluent Schema
  Registry](https://docs.confluent.io/platform/current/schema-registry/index.html),
  used for [Apache Avro](https://avro.apache.org/docs/current/) schemas
* [Lenses.io Schema Registry
  UI](https://github.com/lensesio/schema-registry-ui), you can access it via
  mDNS at http://schema-registry-ui.playground.local
* A Ruby 2.7 enabled playground container with configured Rimless support

## Examples

### Simple Message Producing/Consuming

Start a playground container with `$ make start` and run the following:

```shell
$ create-topic -v test
```

```shell
$ list-topics

Metadata for all topics (from broker 1001: kafka.playground.local:9092/1001):
 1 brokers:
  broker 1001 at kafka.playground.local:9092 (controller)
 2 topics:
  topic "_schemas" with 1 partitions:
    partition 0, leader 1001, replicas: 1001, isrs: 1001
  topic "test" with 1 partitions:
```

Now start a second teminal playground container with `$ make shell` and run:

```shell
# Terminal B

$ consume-topic test

% Waiting for group rebalance
% Group kcat rebalanced (memberid kcat-1ec7324b-463c-4c1e-ab47-b58aa886a98d): assigned: test [0]
% Reached end of topic test [0] at offset 0
```

At the first container session run:

```shell
# Terminal A

$ echo '{"test":true}' | produce-event test -

Processing lines of '/dev/stdin' ..
{"test":true}
```

And see that the consumer at the second terminal output changed to:

```shell
# Terminal B

$ consume-topic test

% Waiting for group rebalance
% Group kcat rebalanced (memberid kcat-1ec7324b-463c-4c1e-ab47-b58aa886a98d): assigned: test [0]
% Reached end of topic test [0] at offset 0
{"test":true}

% Reached end of topic test [0] at offset 1
```

### Message Producing/Consuming with Rimless (Apache Avro)

Setup two terminal playground session containers with `$ make shell` and run
the following snippets to produce an Apache Avro message and consume it with
[kcat](https://github.com/edenhill/kcat):

```shell
# Terminal A

$ create-topic production.playground-app.payments
$ consume-topic -s value=avro production.playground-app.payments
```

And at the otherside run:

```shell
# Terminal B

$ examples/rimless-produce

{"event"=>"payment_authorized",
 "payment"=>
  {"gid"=>"gid://playground-app/Payment/19da4f09-56c8-47d6-8a01-dc7ec2f9daff",
   "currency"=>"eur",
   "net_amount_sum"=>500,
   "items"=>
    [{"gid"=>
       "gid://playground-app/PaymentItem/9f2d9746-52a8-4b8a-a614-4f8f8b4ef4a5",
      "net_amount"=>499,
      "tax_rate"=>19,
      "created_at"=>"2021-10-27T15:09:06.990+00:00",
      "updated_at"=>nil},
     {"gid"=>
       "gid://playground-app/PaymentItem/c8f9f718-03fd-442a-9677-1a4e64349c2c",
      "net_amount"=>1,
      "tax_rate"=>19,
      "created_at"=>"2021-10-27T15:09:06.990+00:00",
      "updated_at"=>nil}],
   "state"=>"authorized",
   "created_at"=>"2021-10-27T15:09:06.990+00:00",
   "updated_at"=>"2021-10-27T15:09:06.990+00:00"}}
```

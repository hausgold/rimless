# AvroTurf RubyGem (relevant changes)

* See: https://github.com/dasch/avro_turf/blob/master/CHANGELOG.md
* Migrated the `avro_turf` gem from `~> 0.11.0` to `~> 1.20`

---

- [Important](#important)
- [Minor](#minor)

## Important

* The `excon` dependency was upgraded to `>= 0.104, < 2`
* Removed `sinatra` as a development dependency (our Rimless gem dropped the
  `sinatra` gem dependency, too)
* Stopped caching nested sub-schemas

## Minor

* Added compatibility with Avro v1.12.x
* Added `resolv_resolver` parameter to `AvroTurf::Messaging` to make use of
  custom domain name resolvers and their options, for example `nameserver` and
  `timeouts`

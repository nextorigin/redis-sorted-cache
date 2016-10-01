# redis-sorted-cache

[![Build Status][ci-nextorigin]][travis-ci]
[![Coverage Status][coverage-nextorigin]][coveralls]
[![Dependency Status][dependency]][david]
[![devDependency Status][dev-dependency]][david-dev]
[![Downloads][downloads]][npm-package]

A helper class to expire keys from a sorted set in Redis, useful for timeseries caches

[![NPM][npm-stats]][npm-package]

## Installation
```sh
npm install --save redis-sorted-cache
```

## Usage

##### Store a JSON object (timeseries event) in Redis and later retrieve all events within the cache TTL

From [https://github.com/nextorigin/godot2/.../src/godot/reactor/redis-cache.coffee#L31](https://github.com/nextorigin/godot2/blob/be70857187d83ec66188609db2d12e8a9d5209ea/src/godot/reactor/redis-cache.coffee#L31)

```coffee
    SortedCache   = require "redis-sorted-cache"
    @cache        = new SortedCache {redis: @client, name: @id, @ttl}

  save: (redis, data, callback) ->
    ideally = errify callback

    data  = flatten data
    saved = []
    for key, val of data when key isnt "ttl"
      val = JSON.stringify val if key in ["tags"]
      saved.push key, val

    key    = "godot:#{@id}:#{data.host}:#{data.service}:#{data.time}"
    expire = @ttl or data.ttl
    ttl    = if @changeTtl then @ttl else data.ttl

    multi  = redis.multi()
    multi.hmset key, "ttl", ttl, saved...
         .EXPIRE key, expire
    await multi.exec ideally defer()
    @cache.addToSet key, data.time, callback

  load: =>
    ideally = errify @error

    await @cache.keys ideally defer keys
    multi = @client.multi()
    multi.hgetall key for key in keys
    await multi.exec ideally defer datas

    for data in datas
      data = unflatten data
      continue unless data
      types     = Producer::types
      data[key] = JSON.parse data[key] for key, type of types when data[key] and typeof data[key] isnt type
      @push data

    return

```

## License

MIT

  [ci-nextorigin]: https://img.shields.io/travis/nextorigin/redis-sorted-cache/master.svg?style=flat-square
  [travis-ci]: https://travis-ci.org/nextorigin/redis-sorted-cache
  [coverage-nextorigin]: https://img.shields.io/coveralls/nextorigin/redis-sorted-cache/master.svg?style=flat-square
  [coveralls]: https://coveralls.io/r/nextorigin/redis-sorted-cache
  [dependency]: https://img.shields.io/david/nextorigin/redis-sorted-cache.svg?style=flat-square
  [david]: https://david-dm.org/nextorigin/redis-sorted-cache
  [dev-dependency]: https://img.shields.io/david/dev/nextorigin/redis-sorted-cache.svg?style=flat-square
  [david-dev]: https://david-dm.org/nextorigin/redis-sorted-cache?type=dev
  [downloads]: https://img.shields.io/npm/dm/redis-sorted-cache.svg?style=flat-square
  [npm-package]: https://www.npmjs.org/package/redis-sorted-cache
  [npm-stats]: https://nodei.co/npm/redis-sorted-cache.png?downloads=true&downloadRank=true&stars=true

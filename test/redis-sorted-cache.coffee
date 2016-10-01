{expect} = require "chai"
Redis    = require "redis"
errify   = require "errify"


RedisSortedCache = require "../src/redis-sorted-cache"


describe "RedisSortedCache", ->
  redis = Redis.createClient()
  cache = null
  name  = "sorted-cache-test"
  key_b = "sorted-cache-test:testkey"
  key_i = 0
  key   = null
  value = null
  key2   = null
  value2 = null
  ttl   = 1

  beforeEach ->
    cache = new RedisSortedCache {redis, name, ttl}
    value = "hello-#{key_i}"
    key   = "#{key_b}#{key_i++}"
    value2 = "hello-#{key_i}"
    key2   = "#{key_b}#{key_i++}"


  afterEach (done) ->
    ideally = errify done
    await redis.del name, ideally defer()
    cache.stopAutoExpire()
    cache = null
    key   = null
    value = null
    key2   = null
    value2 = null
    done()

  describe "##constructor", ->
    it "should set redis, name, ttl, and cacheTtl on the instance", ->
      expect(cache.redis).to.exist
      expect(cache.redis).to.be.an "object"
      expect(cache.name).to.equal name
      expect(cache.ttl).to.be.a "number"
      expect(cache.ttl).to.equal ttl
      expect(cache.cacheTtl).to.equal ttl + 60

  describe "add", ->
    it "should add a key and add it to the set", (done) ->
      ideally = errify done

      await cache.add key, value, ideally defer()

      await redis.zrange name, 0, -1, ideally defer keys
      expect(keys[0]).to.equal key
      await redis.get key, ideally defer result
      expect(result).to.equal value
      done()

    it "should expire the set list after cacheTtl", (done) ->
      ideally = errify done
      cacheTtl = 1
      cache.cacheTtl = cacheTtl

      await cache.add key, value, ideally defer()

      await setTimeout defer(), cacheTtl * 1000
      await redis.zrange name, 0, -1, ideally defer result
      expect(result).to.be.empty
      done()

  describe "addToSet", ->
    it "should add a key to the set", (done) ->
      ideally = errify done

      await cache.addToSet key, ideally defer()

      await redis.zrange name, 0, -1, ideally defer keys
      expect(keys[0]).to.equal key
      done()

    it "should accept a custom timestamp/score", (done) ->
      ideally = errify done
      timestamp = Date.now() - 1000

      await cache.addToSet key, timestamp, ideally defer()

      await redis.ZRANGEBYSCORE name, (timestamp - 500), (timestamp + 500), ideally defer keys
      expect(keys[0]).to.equal key
      done()

    it "should expire the set list after cacheTtl", (done) ->
      ideally = errify done
      cacheTtl = 1
      cache = new RedisSortedCache {redis, name, ttl, cacheTtl}

      await cache.add key, value, ideally defer()

      await setTimeout defer(), cacheTtl * 1000
      await redis.zrange name, 0, -1, ideally defer result
      expect(result).to.be.empty
      done()

  describe "all", ->
    it "should return all the values from the set", (done) ->
      ideally = errify done

      await cache.add key, value, ideally defer()
      await cache.add key2, value2, ideally defer()

      await cache.all ideally defer values
      expect(values).to.have.length 2
      expect(values[0]).to.equal value
      expect(values[1]).to.equal value2
      done()

    it "should return all the values from the set from a specified ttl", (done) ->
      ideally = errify done
      _ttl   = 4
      timestamp = Date.now() - _ttl * 1000

      multi = redis.multi()
      multi.set key, value, "EX", _ttl
           .set key2, value2, "EX", _ttl
      await multi.exec ideally defer()

      await cache.addToSet key, timestamp, ideally defer()
      await cache.addToSet key2, timestamp, ideally defer()

      await cache.all (_ttl + 1), ideally defer values
      expect(values).to.have.length 2
      expect(values[0]).to.equal value
      expect(values[1]).to.equal value2
      done()

  describe "expire", ->
    it "should remove keys from before ttl", (done) ->
      ideally = errify done

      await cache.add key, value, ideally defer()
      await cache.add key2, value2, ideally defer()

      await setTimeout defer(), 50
      await cache.expire ideally defer()

      await cache.all ideally defer values
      expect(values).to.have.length 2
      expect(values[0]).to.equal value
      expect(values[1]).to.equal value2

      await setTimeout defer(), ttl * 1000
      await cache.expire ideally defer()

      await cache.keys ideally defer keys
      expect(keys).to.be.empty
      done()

  describe "autoExpire", ->
    it "should automatically remove keys from before ttl", (done) ->
      ideally = errify done

      await cache.add key, value, ideally defer()
      await cache.add key2, value2, ideally defer()

      cache.autoExpire()
      await setTimeout defer(), 50

      await cache.all ideally defer values
      expect(values).to.have.length 2
      expect(values[0]).to.equal value
      expect(values[1]).to.equal value2

      await setTimeout defer(), ttl * 1000

      await cache.all ideally defer values
      expect(values).to.not.exist
      done()

  describe "stopAutoExpire", ->
    it "should stop automatically removing keys", (done) ->
      ideally = errify done

      await cache.add key, value, ideally defer()
      await cache.add key2, value2, ideally defer()

      cache.autoExpire()
      await setTimeout defer(), 50

      cache.stopAutoExpire()
      await setTimeout defer(), ttl * 1000

      await cache.keys ttl + 1, ideally defer keys
      expect(keys).to.have.length 2
      done()

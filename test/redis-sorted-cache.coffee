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
  ttl   = 1

  beforeEach ->
    cache = new RedisSortedCache {redis, name, ttl}
    value = "hello-#{key_i}"
    key   = "#{key_b}#{key_i++}"

  afterEach (done) ->
    ideally = errify done
    await redis.del name, ideally defer()
    cache = null
    key   = null
    value = null
    done()

  describe "##constructor", ->
    it "should set redis, name, and ttl on the instance", ->
      expect(cache.redis).to.exist
      expect(cache.redis).to.be.an "object"
      expect(cache.name).to.equal name
      expect(cache.ttl).to.be.a "number"
      expect(cache.ttl).to.equal ttl

  describe "add", ->
    it "should add a key and add it to the set", (done) ->
      ideally = errify done

      await cache.add key, value, ideally defer()

      await redis.zrange name, 0, -1, ideally defer keys
      expect(keys[0]).to.equal key
      await redis.get key, ideally defer result
      expect(result).to.equal value
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

  describe "all", ->
    it "should return all the values from the set", (done) ->
      ideally = errify done
      value2 = "hello-#{key_i}"
      key2   = "#{key_b}#{key_i++}"

      await cache.add key, value, ideally defer()
      await cache.add key2, value2, ideally defer()

      await cache.all ideally defer values
      expect(values).to.have.length 2
      expect(values[0]).to.equal value
      expect(values[1]).to.equal value2
      done()





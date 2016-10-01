errify = require "errify"


class RedisSortedCache
  constructor: ({@redis, @name, @ttl}) ->
    throw new Error "redis client and ttl required" unless @redis and @ttl
    @name or= "sortedcache"

  # add key to set with expiry
  add: (key, value, timestamp = Date.now(), callback) ->
    if typeof timestamp is "function"
      callback = timestamp
      timestamp = Date.now()

    multi = @redis.multi()
    multi.set key, value, "EX", @ttl
         .zadd @name, timestamp, key
         .exec callback

  # add key to set
  addToSet: (key, timestamp = Date.now(), callback) ->
    if typeof timestamp is "function"
      callback = timestamp
      timestamp = Date.now()

    @redis.zadd @name, timestamp, key, callback

  _parseArgs: (ttl, callback) ->
    if typeof ttl is "function"
      callback = ttl
      ttl = @ttl
    {ttl, callback}

  # get all key values since ttl
  all: ->
    {ttl, callback} = @_parseArgs arguments...
    ideally = errify callback
    await @keys ttl, ideally defer keys
    @redis.mget keys..., callback

  # get all keys since ttl
  keys: ->
    {ttl, callback} = @_parseArgs arguments...
    cutoff = Date.now() - ttl * 1000
    @redis.ZRANGEBYSCORE @name, cutoff, "+inf", callback

  # remove keys from before ttl
  expire: =>
    {ttl, callback} = @_parseArgs arguments...
    cutoff = Date.now() - ttl * 1000
    @redis.ZREMRANGEBYSCORE @name, "-inf", cutoff, callback

  autoExpire: (ttl = @ttl, interval = @ttl) ->
    @_expirer = setInterval (@expire.bind this, ttl), interval * 1000

  stopAutoExpire: ->
    clearInterval @_expirer if @_expirer


module.exports = RedisSortedCache

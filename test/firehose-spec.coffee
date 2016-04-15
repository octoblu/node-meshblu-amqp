async                 = require 'async'
{Client}              = require 'amqp10'
Promise               = require 'bluebird'
MeshbluAmqp           = require '../'
uuid                  = require 'uuid'
TestFirehoseConnector = require './test-firehose-connector'
RedisNS               = require '@octoblu/redis-ns'
redis                 = require 'ioredis'

describe '-> firehose', ->
  beforeEach (done) ->
    @testConnector = new TestFirehoseConnector
    @testConnector.connect (error, {@client, @receiver}) =>
      return done error if error?
      done()


  afterEach (done) ->
    @sut.disconnectFirehose done

  afterEach (done) ->
    @testConnector.close done

  beforeEach (done) ->
    @sut = new MeshbluAmqp uuid: 'some-uuid', token: 'some-token', hostname: '127.0.0.1'
    @sut.connect (error) =>
      return done error if error?
      @sut.connectFirehose done

  beforeEach (done) ->
    @sut.on 'message', (@message) =>
      done()

    async.until (=> @testConnector.hydrantConnected), ((cb) => setTimeout(cb, 50)), =>
      redisClient = new RedisNS 'messages', redis.createClient()
      redisClient.on 'ready', =>
        redisClient.publish 'some-uuid', JSON.stringify(foo: 'bar'), (error, published) =>
          return done error if error?
          return done(new Error 'failed to publish') if published == 0

  it 'should emit a message', ->
    expect(@message).to.exist

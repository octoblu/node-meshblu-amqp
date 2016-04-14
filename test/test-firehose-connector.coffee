{Client}       = require 'amqp10'
Promise        = require 'bluebird'
HydrantManager = require 'meshblu-core-manager-hydrant'
redis          = require 'ioredis'
RedisNS        = require '@octoblu/redis-ns'

class TestFirehoseConnector
  constructor: ->
    @uuidAliasResolver = resolve: (uuid, callback) => callback null, uuid

  connect: (callback) =>
    options =
      reconnect:
        forever: false
        retries: 0

    @client = new Client options
    @client.connect 'amqp://meshblu:judgementday@127.0.0.1'
      .then =>
        Promise.all [
          @client.createReceiver('meshblu.firehose.request')
          @client.createSender()
        ]
      .spread (@receiver, @sender) =>
        callback null, {@receiver, @client, @sender}
        @receiver.on 'message', @_onMessage
        return true
      .catch (error) =>
        callback error
      .error (error) =>
        callback error

  close: (callback) =>
    @client.disconnect()
      .then callback
      .catch callback

  _onMessage: (message) =>
    if message.applicationProperties.jobType == 'ConnectFirehose'
      redisClient = new RedisNS 'messages', redis.createClient()
      @hydrant = new HydrantManager {client: redisClient, @uuidAliasResolver}

      return @hydrant.connect uuid: message.applicationProperties.toUuid, (error) =>
        throw error if error?
        @hydrantConnected = true
        @hydrant.on 'message', (redisMessage) =>
          options =
            properties:
              subject: message.properties.replyTo
              correlationId: message.properties.correlationId

          @sender.send redisMessage, options

    if message.applicationProperties.jobType == 'DisconnectFirehose'
      return @hydrant.close()

module.exports = TestFirehoseConnector

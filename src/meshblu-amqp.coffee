{Client} = require 'amqp10'
Promise = require 'bluebird'
uuid = require 'uuid'

class MeshbluAmqp
  constructor: ({@uuid, @token})->
    @queueName = "#{@uuid}.#{uuid.v4()}"

  connect: (callback) =>
    options =
      reconnect:
        forever: false
        retries: 0

    @client = new Client options
    @client.connect "amqp://#{@uuid}:#{@token}@192.168.99.100"
      .then =>
        Promise.all [
          @client.createSender()
          @client.createReceiver(@queueName)
        ]
      .spread (@sender,@receiver) =>
        callback()
      .catch (error) =>
        callback error
      .error (error) =>
        callback error

  whoami: (callback) =>
    requestId = uuid.v4()
    onMessage = (message) =>
      if message.properties.correlationId == requestId
        @receiver.removeListener 'message', onMessage
        callback null, message.body

    options =
      properties:
        replyTo: @queueName
        subject: 'meshblu.request'
        correlationId: requestId
        userId: @uuid
      applicationProperties:
        jobType: 'GetDevice'
        toUuid: 'abcd'

    @receiver.on 'message', onMessage
    @sender.send {}, options

module.exports = MeshbluAmqp

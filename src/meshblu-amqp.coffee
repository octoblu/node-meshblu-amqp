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
          @client.createSender("meshblu.requests")
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
      console.log 'whoami: ', message, requestId
      if message.properties.correlationId == requestId
        callback null, message.body
        @receiver.removeListener 'message', onMessage

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

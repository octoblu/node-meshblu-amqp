{Client} = require 'amqp10'
Promise = require 'bluebird'
uuid = require 'uuid'

class MeshbluAmqp
  constructor: ({@uuid, @token})->

  connect: (callback) =>
    options =
      reconnect:
        forever: false
        retries: 0
    @client = new Client options
    @client.connect "amqp://#{@uuid}:#{@token}@192.168.99.100"
      .then =>
        Promise.all [
          @client.createSender("/request/queue")
        ]
      .spread (@sender) =>
        callback()
      .catch (error) =>
        callback error
      .error (error) =>
        callback error

  whoami: (callback) =>
    requestId = uuid.v4()
    @client.createReceiver("#{@uuid}.response.#{requestId}")
      .then (receiver) =>
        receiver.on 'message', (message) =>
          callback null, message.body

        options =
          properties:
            replyTo: "#{@uuid}.response.#{requestId}"
          applicationProperties:
            metadata:
              jobType: 'GetDevice'
              toUuid: 'abcd'

        @sender.send {}, options
      .catch callback


module.exports = MeshbluAmqp

{Client} = require 'amqp10'
Promise = require 'bluebird'

class MeshbluAmqp
  constructor: ->

  connect: (callback) =>
    options = reconnect:
      forever: false
      retries: 0
    client = new Client options
    client.connect 'amqp://192.168.99.100'
      .then =>
        callback()
      #   Promise.all [
      #     client.createReceiver 'amq.topic'
      #   ]
      # .spread (receiver) =>
      #   receiver.once 'errorReceived', (error) =>
      #     callback error

      .catch (error) =>
        callback error
      .error (error) =>
        callback error


module.exports = MeshbluAmqp

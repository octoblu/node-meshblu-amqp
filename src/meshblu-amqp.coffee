{Client} = require 'amqp10'
Promise = require 'bluebird'
uuid = require 'uuid'
URL = require 'url'

class MeshbluAmqp
  constructor: ({@uuid, @token, @hostname, @port})->
    @queueName = "#{@uuid}.#{uuid.v4()}"

  connect: (callback) =>
    options =
      reconnect:
        forever: false
        retries: 0

    @client = new Client options

    url = URL.format
      protocol: 'amqp'
      slashes: true
      auth: "#{@uuid}:#{@token}"
      hostname: @hostname
      port:     @port

    @client.connect url
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

  message: (message, callback) =>
    request =
      metadata:
        jobType: 'SendMessage'
      rawData: JSON.stringify message

    @_do request, callback

  createSessionToken: (toUuid, tags, callback) =>
    metadata =
      toUuid: toUuid

    @_JobSetRequest metadata, tags, 'CreateSessionToken', callback

  register: (opts, callback) =>
    @_JobSetRequest {}, opts, 'RegisterDevice', callback

  searchDevices: (uuid, query={}, callback) =>
    metadata =
      fromUuid: uuid
    @_JobSetRequest metadata, query, 'SearchDevices', callback

  status: (callback) =>
    request =
      metadata:
        jobType: 'GetStatus'

    @_do request, callback

  subscribe: (uuid, opts, callback) =>
    metadata =
      toUuid: uuid
    @_JobSetRequest metadata, opts, 'CreateSubscription', callback

  unsubscribe: (uuid, opts, callback) =>
    @subscribe uuid, opts, callback

  update: (uuid, query, callback) =>
    request =
      metadata:
        jobType: 'UpdateDevice'
        toUuid: uuid
      rawData: JSON.stringify query

    @_do request, callback

  whoami: (callback) =>
    request =
      metadata:
        jobType: 'GetDevice'
        toUuid: @uuid

    @_do request, callback

  _do: (request, callback) =>
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
      applicationProperties: request.metadata

    @receiver.on 'message', onMessage
    @sender.send request.rawData || {}, options

module.exports = MeshbluAmqp

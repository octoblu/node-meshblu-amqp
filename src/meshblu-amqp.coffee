_ = require 'lodash'
{Client} = require 'amqp10'
Promise = require 'bluebird'
uuid = require 'uuid'
URL = require 'url'
{EventEmitter2} = require 'eventemitter2'

class MeshbluAmqp extends EventEmitter2
  constructor: ({@uuid, @token, @hostname, @port})->
    @queueName = "#{@uuid}.#{uuid.v4()}"
    @firehoseQueueName = "#{@uuid}.firehose.#{uuid.v4()}"

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
        return true # oh, promises
      .catch callback
      .error callback

  close: (callback) =>
    @disconnectFirehose =>
      @client.disconnect().asCallback callback

  connectFirehose: (callback) =>
    @client.createReceiver @firehoseQueueName
      .then (@firehose) =>
        @firehose.on 'message', @_onMessage
        @_sendConnectFirehose callback
      .catch callback
      .error callback

  disconnectFirehose: (callback) =>
    return callback() unless @firehose?
    @_sendDisconnectFirehose callback

  message: (data, callback) =>
    @_makeJob 'SendMessage', null, data, callback

  createSessionToken: (uuid, data, callback) =>
    @_makeJob 'CreateSessionToken', toUuid: uuid, data, callback

  register: (data, callback) =>
    @_makeJob 'RegisterDevice', null, data, callback

  unregister: (uuid, callback) =>
    @_makeJob 'UnregisterDevice', toUuid: uuid, null, callback

  searchDevices: (uuid, data={}, callback) =>
    @_makeJob 'SearchDevices', fromUuid: uuid, data, callback

  status: (callback) =>
    @_makeJob 'GetStatus', null, null, callback

  subscribe: (uuid, data, callback) =>
    @_makeJob 'CreateSubscription', toUuid: uuid, data, callback

  unsubscribe: (uuid, data, callback) =>
    @_makeJob 'DeleteSubscription', toUuid: uuid, data, callback

  update: (uuid, data, callback) =>
    @_makeJob 'UpdateDevice', toUuid: uuid, data, callback

  whoami: (callback) =>
    @_makeJob 'GetDevice', toUuid: @uuid, null, callback

  _makeJob: (jobType, metadata, data, callback) =>
    metadata = _.clone metadata || {}
    metadata.jobType = jobType
    metadata.auth = {@uuid, @token}
    if data?
      rawData = JSON.stringify data
    job = {metadata, rawData}

    @_do job, callback

  _onMessage: (message) =>
    newMessage =
      metadata: message.applicationProperties

    if message.body?
      try
        newMessage.data = JSON.parse message.body
      catch
        newMessage.rawData = message.body

    @emit 'message', newMessage

  _do: (job, callback) =>
    requestId = uuid.v4()
    onMessage = (message) =>
      if message.properties.correlationId == requestId
        try
          data = JSON.parse message.body
        catch
          data = message.body
        @receiver.removeListener 'message', onMessage
        callback null, data

    options =
      properties:
        replyTo: @queueName
        subject: 'meshblu.request'
        correlationId: requestId
        userId: @uuid
      applicationProperties: job.metadata

    @receiver.on 'message', onMessage
    @sender.send job.rawData || {}, options

  _sendConnectFirehose: (callback) =>
    requestId = uuid.v4()
    options =
      properties:
        replyTo: @firehoseQueueName
        subject: 'meshblu.firehose.request'
        correlationId: requestId
        userId: @uuid
      applicationProperties:
        jobType: 'ConnectFirehose'
        toUuid: @uuid

    @sender.send({}, options)
      .then =>
        callback()
        return true # promises
      .catch callback

  _sendDisconnectFirehose: (callback) =>
    requestId = uuid.v4()
    options =
      properties:
        replyTo: @firehoseQueueName
        subject: 'meshblu.firehose.request'
        correlationId: requestId
        userId: @uuid
      applicationProperties:
        jobType: 'DisconnectFirehose'
        toUuid: @uuid

    @sender.send({}, options)
      .then =>
        callback()
        return true # promises
      .catch callback

module.exports = MeshbluAmqp

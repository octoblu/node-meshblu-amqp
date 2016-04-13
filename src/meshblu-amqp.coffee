_ = require 'lodash'
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

  close: (callback) =>
    @client.disconnect()
      .then callback
      .catch callback

  message: (data, callback) =>
    @_makeJob 'SendMessage', null, data, callback

  createSessionToken: (uuid, data, callback) =>
    @_makeJob 'CreateSessionToken', toUuid: uuid, data, callback

  register: (data, callback) =>
    @_makeJob 'RegisterDevice', null, data, callback

  searchDevices: (uuid, data={}, callback) =>
    @_makeJob 'SearchDevices', fromUuid: uuid, data, callback

  status: (callback) =>
    @_makeJob 'GetStatus', null, null, callback

  subscribe: (uuid, data, callback) =>
    @_makeJob 'CreateSubscription', null, data, callback

  unsubscribe: (uuid, data, callback) =>
    @_makeJob 'DeleteSubscription', null, data, callback

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

  _do: (job, callback) =>
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
      applicationProperties: job.metadata

    @receiver.on 'message', onMessage
    @sender.send job.rawData || {}, options

module.exports = MeshbluAmqp

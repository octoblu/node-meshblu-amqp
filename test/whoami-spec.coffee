{Client} = require 'amqp10'
Promise = require 'bluebird'
MeshbluAmqp = require '../'
uuid = require 'uuid'

describe '-> whoami', ->
  describe 'with an active connection', ->
    beforeEach (done) ->
      options =
        reconnect:
          forever: false
          retries: 0

      @client = new Client options
      @client.connect 'amqp://meshblu:judgementday@127.0.0.1'
        .then =>
          @client.createReceiver('meshblu.request')
        .then (@receiver) =>
          done()
          return true
        .catch (error) =>
          done error
        .error (error) =>
          done error

    beforeEach ->
      @receiver.on 'message', (@message) =>
        @client.createSender(@message.properties.replyTo).then (sender) =>
          options =
            properties:
              correlationId: @message.properties.correlationId
            applicationProperties:
              code: 200

          sender.send {uuid: @message.applicationProperties.toUuid, online: true}, options

    beforeEach (done) ->
      @sut = new MeshbluAmqp uuid: 'some-uuid', token: 'some-token', hostname: '127.0.0.1'
      @sut.connect (error) =>
        return done error if error?
        @sut.whoami (error, @data) =>
          return done error if error?
          done()

    it 'should sent a proper request', ->
      expect(@message.body).to.deep.equal {}

    it 'should return the device', ->
      expect(@data).to.deep.equal {uuid: 'some-uuid', online: true}

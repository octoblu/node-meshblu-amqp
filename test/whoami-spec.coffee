MeshbluAmqp = require '../'
uuid = require 'uuid'
TestWorker = require './test-worker'

describe '-> whoami', ->
  beforeEach (done) ->
    @testWorker = new TestWorker
    @testWorker.connect (error, {@client, @receiver}) =>
      return done error if error?
      done()

  afterEach (done) ->
    @testWorker.close done

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
    expectedProperties =
      jobType: 'GetDevice'
      toUuid: 'some-uuid'
      auth:
        uuid: 'some-uuid'
        token: 'some-token'

    expect(@message.applicationProperties).to.containSubset expectedProperties

  it 'should return the device', ->
    expect(@data).to.deep.equal {uuid: 'some-uuid', online: true}

{Client} = require 'amqp10'
Promise = require 'bluebird'
MeshbluAmqp = require '../'
uuid = require 'uuid'
TestWorker = require './test-worker'

describe '-> register', ->
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

        sender.send [foo: true, uuid: 'foo-uuid'], options

  beforeEach (done) ->
    @sut = new MeshbluAmqp uuid: 'some-uuid', token: 'some-token', hostname: '127.0.0.1'
    @sut.connect (error) =>
      return done error if error?
      @sut.register foo: true, (error, @data) =>
        return done error if error?
        done()

  it 'should sent a proper request', ->
    expectedProperties =
      jobType: 'RegisterDevice'
      auth:
        uuid: 'some-uuid'
        token: 'some-token'

    expectedBody =
      foo: true

    expect(@message.applicationProperties).to.containSubset expectedProperties
    expect(JSON.parse @message.body).to.deep.equal expectedBody

  it 'should return the results', ->
    expect(@data).to.deep.equal [{foo: true, uuid: 'foo-uuid'}]

{Client} = require 'amqp10'
Promise = require 'bluebird'
MeshbluAmqp = require '../'
uuid = require 'uuid'

describe '->whoami', ->
  beforeEach (done) ->
    options = reconnect:
      forever: false
      retries: 0
    @client = new Client options
    @client.connect 'amqp://meshblu:05539223b927d3091eb1d53dcb31a6ff92cc8edf@192.168.99.100'
      .then =>
        Promise.all [
          @client.createReceiver('/request/queue')
        ]
      .spread (@receiver) =>
        done()
        return true
      .catch (error) =>
        done error
      .error (error) =>
        done error

  beforeEach ->
    @receiver.on 'message', (message) =>
      @client.createSender(message.properties.replyTo).then (sender) =>
        sender.send {uuid: 'foo', online: true}

  beforeEach (done) ->
    @sut = new MeshbluAmqp uuid: 'e6352208-79a4-4bb1-8724-c5c18b7eef8a', token: '24a799fab1d5eba3fe430c2464487fbe3e2f2a0d'
    @sut.connect (error) =>
      return done error if error?
      @sut.whoami (error, @data) =>
        return done error if error?
        done()

  it 'should return the device', ->
    expect(@data).to.deep.equal {uuid: 'foo', online: true}

MeshbluAmqp = require '../'

describe 'connect', ->
  beforeEach (done) ->
    @sut = new MeshbluAmqp uuid: 'e6352208-79a4-4bb1-8724-c5c18b7eef8a', token: '24a799fab1d5eba3fe430c2464487fbe3e2f2a0d'
    @sut.connect (@error) =>
      done()

  it 'should connect without error', ->
    expect(@error).not.to.exist

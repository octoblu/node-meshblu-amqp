MeshbluAmqp = require '../'

describe 'connect', ->
  beforeEach (done) ->
    @sut = new MeshbluAmqp
    @sut.connect (@error) =>
      done()

  it 'should connect without error', ->
    expect(@error).not.to.exist

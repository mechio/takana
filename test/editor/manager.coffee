editor         = require '../../lib/editor'
sinon          = require 'sinon'
nssocket       = require 'nssocket'

describe 'editor.Manager', ->
  before (done) ->
    @editorManager = new editor.Manager(port: 5000)
    @editorManager.start done

  after ->
    @editorManager.stop()
    

  it 'should emit buffer:update when the editor updates its buffer', (done) ->
    outbound = new nssocket.NsSocket()
    payload  = path: '/path/to/some/file'

    @editorManager.once 'buffer:reset', (data) ->
      data.should.eql(payload)
      done()

    outbound.on 'start', ->
      outbound.send ['editor', 'reset'], payload
        
    outbound.connect(@editorManager.port)

  it 'should emit buffer:clear when the editor clears its buffer', (done) ->
    outbound = new nssocket.NsSocket()
    payload  = 
      path: '/path/to/some/file'
      created_at: 123456
      buffer: 'hello jag jag'

    @editorManager.once 'buffer:update', (data) ->
      data.path.should.eql(payload.path)
      data.timestamp.should.eql(payload.created_at)
      data.buffer.should.eql(payload.buffer)
      done()

    outbound.on 'start', ->
      outbound.send ['editor', 'update'], payload
        
    outbound.connect(@editorManager.port)

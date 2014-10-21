Server = require '../lib/server' 
path   = require 'path'
sinon  = require 'sinon'
_      = require 'underscore'

scratchPath = path.join(createEmptyTmpDir(), 'scratchy')


describe 'Server', ->
  beforeEach ->
    @server = new Server({
      name:         'default',
      path:         fixturePath('foundation5'),
      scratchPath:  scratchPath
      includePaths: []
    });

  describe 'start', ->
    beforeEach (done) ->
      @startSpies = [
        sinon.spy(@server.webServer, 'listen')
        sinon.spy(@server.editorManager, 'start')
        sinon.spy(@server.browserManager, 'start')
        sinon.spy(@server.folder, 'start')
      ]
      @server.start(done)

    afterEach (done) ->
      @server.stop(done)
      @startSpies.forEach (spy) -> spy.restore()

    it 'should create the scratchPath folder', ->
      assertIsFolder(true, @server.options.scratchPath)

    it 'should start its subservices', ->
      @startSpies.forEach (spy) ->
        spy.calledOnce.should.be.true
  
  context 'when the server is running', ->
    beforeEach (done) ->
      @server.start(done)

    afterEach (done) ->
      @server.stop(done)

    context 'received folder updated event', ->
      it 'should call handleFolderUpdate', ->
        stub = sinon.stub(@server, 'handleFolderUpdate')
        @server.folder.emit('updated')
        stub.called.should.be.true
        stub.restore()

    context 'received buffer:update event', ->
      it 'should call bufferUpdate on the folder', ->
        stub = sinon.stub(@server.folder, 'bufferUpdate')
        data = path: @server.options.path + '/some/file.scss'

        @server.editorManager.emit('buffer:update', data)
        stub.calledWith(data).should.be.true
        stub.restore()
        
    context 'received buffer:reset event', ->
      it 'should call bufferClear on the folder', ->
        stub = sinon.stub(@server.folder, 'bufferClear')
        data = path: @server.options.path + '/some/file.scss'

        @server.editorManager.emit('buffer:reset', data)
        stub.calledWith(data.path).should.be.true
        stub.restore()
        
    context 'received stylesheet:resolve event', ->
      context 'matching stylesheet', ->
        it 'should callback with the path of the matched stylesheet', (done) ->
          @server.browserManager.emit 'stylesheet:resolve', {href: '/css/app.css'}, (error, match) ->
            done()

      context 'no matching stylesheet', ->
        it 'should callback with an error'

    describe 'handleFolderUpdate', ->
      it 'should render all watched stylesheets on the project'
      it 'should work with include paths'
      context 'successful render', ->
        it 'should notify the browser manager'


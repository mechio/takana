Client = require '../../lib/client'
Server = require '../../lib/server'
path   = require 'path'
shell  = require 'shelljs'

describe 'Client', ->
  before ->
    @client  = new Client()


  context 'server running', ->
    before (done) ->
      testDB = path.join(__dirname, '..', 'tmp', 'database.yml')
      shell.rm '-f', testDB

      @server = new Server( 
        database: testDB 
        logger:   testLogger
        path:     'path/to/some/'
      )
      @server.start ->
        done()

    after (done) ->
      @server.stop ->
        done()

    describe 'getStatus', ->
      it 'should be { running: true } if Takana is ON', (done) ->
        @client.getStatus (status) ->
          status.running.should.equal(true)
          done()

            

  context 'server stopped', ->
    describe 'getStatus', ->
      it 'should be { running: false } is Takana is OFF', (done) ->    
        @client.getStatus (status) ->
          status.running.should.be.false
          done()
  









browser         = require '../../lib/browser_manager'
sinon           = require 'sinon'
http            = require 'http'
WebSocketClient = require('websocket').client
_               = require 'underscore'
Q               = require 'q'
{EventEmitter}  = require 'events'


PORT = 50001

mockConnection = ->
  new EventEmitter

newBrowserConnection = (projectName, callback) ->
  client = new WebSocketClient()

  client.on "connectFailed", (error) ->
    callback?(e)
    console.error "connect error: " + error.toString()
  
  client.on "connect", (connection) ->
    connection.sendMessage = (event, data) ->
      @sendUTF(JSON.stringify(
        event: event
        data:  data
      ))

    connection.on 'message', (message) ->
      message = if message.binaryData
        JSON.parse(message.binaryData.toString())
      else if message.utf8Data
        JSON.parse(message.utf8Data)

      @emit 'message:parsed', message


    callback?(null, connection)

  client.connect "ws://localhost:#{PORT}/browser?project_name=#{projectName}"


describe 'BrowserManager', ->
  before (done) ->
    @webServer      = http.createServer()
    @browserManager = new browser.Manager(
      webServer : @webServer
      logger    : testLogger
    )
    @browserManager.start()
    @webServer.listen PORT, done

  after () ->
    @webServer.close()
  
  context 'when a browsers connect and disconnect', ->
    it 'should adjust its internal state accordingly', (done) ->
      browserList    = => _.values(@browserManager.browsers)
      browserManager = @browserManager

      browserList().should.be.empty

      Q.nfcall(newBrowserConnection, 'project1')
        .then (@connection1) ->
          browserList().length.should.equal(1)
          @browser1    = browserList()[0]
          Q.nfcall(newBrowserConnection, 'project2')
        .then (@connection2) ->
          browserList().length.should.equal(2)
          Q.nfcall(newBrowserConnection, 'project3')
        .then (@connection3) ->
          browserList().length.should.equal(3)
          @connection1.close()
          setTimeout =>
            (browserManager.browsers[@browser1.id] == undefined).should.be.true
            @connection2.close()
            @connection3.close()
            setTimeout =>
              browserList().should.be.empty
              done()
            , 10
          , 10

        .fail (e) ->
          throw e
        .done()
      
  context 'when the browser sends stylesheet:resolve', ->

    beforeEach (done) ->
      @payload = 
        project_name : 'project'
        href         : 'http://reddit.com/stylesheet.css'

      newBrowserConnection 'some_project', (e, @connection) => done()

    afterEach ->
      @connection.close()

    it 'should emit a styleheet:resolve message', (done) ->
      @browserManager.once 'stylesheet:resolve', (data, callback) =>
        data.should.eql(@payload)
        callback.should.be.a.Function
        done()

      @connection.sendMessage('stylesheet:resolve', @payload)
      
    it 'should send styleheet:resolved to the browser after it is called back', (done) ->
      console.log @connection.sendMessage
      resolvedId = '698726429736'

      @browserManager.once 'stylesheet:resolve', (data, callback) =>
        callback(resolvedId)
        
      @connection.once 'message:parsed', (message) =>
        message.event.should.equal('stylesheet:resolved')
        message.data.project_name.should.equal(@payload.project_name)
        message.data.href.should.equal(@payload.href)
        message.data.id.should.equal(resolvedId)
        done()

      @connection.sendMessage('stylesheet:resolve', @payload)
      

  context 'when the browser sends styleheet:listen', ->

    beforeEach (done) ->
      @payload = id: 'stylesheet1'
      newBrowserConnection 'some_project', (e, @connection) => done()

    afterEach ->
      @connection.close()

    it 'should add it to the watchers list', (done) ->
      browserList    = => _.values(@browserManager.browsers)
      
      @browserManager.once 'stylesheet:listen', =>
        browserList()[0].watchedStylesheets.should.containEql(@payload.id)
        done()

      @connection.sendMessage 'stylesheet:listen', @payload
      
    
    it 'should emit styleheet:listen', (done) ->
      @browserManager.once 'stylesheet:listen', ->
        done()

      @connection.sendMessage 'stylesheet:listen', @payload


  describe 'watchedStylesheetsForProject', ->
    it 'should return the set of stylesheets that are being watched accross all browsers', ->
      browser1 = new browser.Browser(
        connection  : mockConnection()
        projectName : 'a_project'
      )

      browser2 = new browser.Browser(
        connection  : mockConnection()
        projectName : 'a_project'
      )

      browser1.watchedStylesheets.push(1)
      browser2.watchedStylesheets.push(2)

      @browserManager.browsers[browser1.id] = browser1
      @browserManager.browsers[browser2.id] = browser2

      @browserManager.watchedStylesheetsForProject('a_project').should.eql([1,2])

  describe 'stylesheetRendered', ->
    it 'should notify interested browsers that a render has occurred'


describe 'Browser', ->


  
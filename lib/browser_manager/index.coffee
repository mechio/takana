WebSocketServer     = require('websocket').server
WebSocketConnection = require('websocket').connection
logger              = require '../support/logger'
helpers             = require '../support/helpers'
{EventEmitter}      = require 'events'



class Browser extends EventEmitter
  constructor: (@options={}) ->
    @id                 = helpers.guid()
    @logger             = @options.logger || logger.silentLogger()
    @watchedStylesheets = []
    @connection         = @options.connection
    @projectName        = @options.projectName
    
    if !@connection || !@projectName
      throw 'Browser not instantiated with correct options'

  handleMessage: (event, data) ->
    switch event
      when 'stylesheet:resolve'
        @emit 'stylesheet:resolve', data, (id) =>
          data.id = id
          @connection.sendMessage 'stylesheet:resolved', data

      when 'stylesheet:listen'
        @watchedStylesheets.push data.stylesheet_id
        @emit 'stylesheet:listen', data.stylesheet_id

class BrowserManager extends EventEmitter
  constructor: (@options={}) ->
    @logger          = @options.logger || logger.silentLogger()
    @webServer       = @options.webServer

    @browsers        = {}
    if !@webServer
      throw 'BrowserManager not instantiated with correct options'


  start: ->
    @websocketServer = new WebSocketServer(
      httpServer            : @webServer
      autoAcceptConnections : false
    )

    @websocketServer.on 'request', (request) =>
      return unless request.resourceURL.pathname == '/browser'
      connection            = request.accept()
      browser               = new Browser(
        connection  : connection
        projectName : request.resourceURL.query.project_name
      )

      helpers.pipeEvent('stylesheet:resolve', browser, @)
      helpers.pipeEvent('stylesheet:listen', browser, @)

      @browsers[browser.id] = browser

      @logger.debug "browser connected to project '#{browser.projectName}'"

      connection.on 'message', (message) =>
        message = if message.binaryData
          JSON.parse(message.binaryData.toString())
        else if message.utf8Data
          JSON.parse(message.utf8Data)

        @logger.trace "received event: '#{message.event}', data:", message.data

        browser.handleMessage(message.event, message.data)
      
      connection.sendMessage = (event, data) ->
        @sendUTF JSON.stringify(
          event : event
          data  : data
        )

      connection.on 'close', =>
        @logger.debug "browser disconnected"
        connection.removeAllListeners()
        delete @browsers[browser.id]


  stop: ->
      

module.exports = BrowserManager


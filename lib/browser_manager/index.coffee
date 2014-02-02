WebSocketServer     = require('websocket').server
WebSocketConnection = require('websocket').connection
logger              = require './support/logger'

{EventEmitter}      = require 'events'

WebSocketConnection.prototype.sendMessage = (event, data) ->
  @sendUTF JSON.stringify(
    event : event
    data  : data
  )

class BrowserManager extends EventEmitter
  constructor: (@options={}) ->
    @logger          = @options.logger || logger.silentLogger()
    @webServer       = @options.webServer

    if !@webServer
      throw 'BrowserManager not instantiated with correct options'


  start: ->
    @websocketServer = new WebSocketServer(
      httpServer            : @webServer
      autoAcceptConnections : false
    )

    @websocketServer.on 'request', (request) =>
      @logger.debug "new browser connection on: " + request.resourceURL.path

      connection = request.accept()

      connection.on 'message', (message) =>
        message = if message.binaryData
          JSON.parse(message.binaryData.toString())
        else if message.utf8Data
          JSON.parse(message.utf8Data)

        @handleMessage(message.event, message.data)
      
      switch request.resourceURL.pathname
        when '/browser'
          projectName = request.resourceURL.query.projectName
          console.log "PROJECT NAME", projectName


  handleMessage: (event, message) ->
    @logger.trace "MESSAGE: ", message


  stop: ->
      

module.exports = BrowserManager


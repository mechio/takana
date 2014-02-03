WebSocketServer     = require('websocket').server
WebSocketConnection = require('websocket').connection
logger              = require '../support/logger'
helpers             = require '../support/helpers'
{EventEmitter}      = require 'events'
_                   = require 'underscore'


class Browser extends EventEmitter
  constructor: (@options={}) ->
    @id                 = helpers.guid()
    @logger             = @options.logger || logger.silentLogger()
    @watchedStylesheets = []
    @connection         = @options.connection
    @projectName        = @options.projectName
    
    if !@connection || !@projectName
      throw 'Browser not instantiated with correct options'

    @connection.on 'message:parsed', @handleMessage.bind(@)



  handleMessage: (message) ->
    event = message.event
    data  = message.data

    @logger.trace "received event: '#{message.event}', data:", message.data

    switch event
      when 'stylesheet:resolve'
        @emit 'stylesheet:resolve', data, (id) =>
          data.id = id
          @connection.sendMessage 'stylesheet:resolved', data

      when 'stylesheet:listen'
        @watchedStylesheets.push data.id
        @emit 'stylesheet:listen', data.id

  stylesheetRendered: (stylesheetId, url) ->
    @logger.trace 'sending stylesheet update to browser'

    if @watchedStylesheets.indexOf(stylesheetId) > -1
      @connection.sendMessage 'stylesheet:updated', id: stylesheetId, url: url

class Manager extends EventEmitter
  constructor: (@options={}) ->
    @logger          = @options.logger || logger.silentLogger()
    @webServer       = @options.webServer

    @browsers        = {}
    if !@webServer
      throw 'BrowserManager not instantiated with correct options'

  watchedStylesheetsForProject: ->

  addBrowser: (browser) ->
    @logger.debug "browser connected to '#{browser.projectName}'"

    helpers.pipeEvent('stylesheet:resolve', browser, @)
    helpers.pipeEvent('stylesheet:listen', browser, @)

    @browsers[browser.id] = browser

    browser.connection.on 'close', =>
      @logger.debug "browser disconnected from", browser.projectName 
      browser.connection.removeAllListeners()
      delete @browsers[browser.id]

  start: ->
    @websocketServer = new WebSocketServer(
      httpServer            : @webServer
      autoAcceptConnections : false
    )

    @websocketServer.on 'request', (request) =>
      return unless request.resourceURL.pathname == '/browser'
      connection            = request.accept()

      connection.on 'message', (message) ->
        message = if message.binaryData
          JSON.parse(message.binaryData.toString())
        else if message.utf8Data
          JSON.parse(message.utf8Data)

        @emit 'message:parsed', message

    
      connection.sendMessage = (event, data) ->
        @sendUTF JSON.stringify(
          event : event
          data  : data
        )

      @addBrowser new Browser(
        connection  : connection
        projectName : request.resourceURL.query.project_name
        logger      : @logger
      )

  stop: ->
  
  allBrowsers: ->
    _.values(@browsers)

  watchedStylesheetsForProject: ->
    stylesheets = []
    @allBrowsers().forEach (browser) ->
      stylesheets = stylesheets.concat(browser.watchedStylesheets)
    stylesheets

  stylesheetRendered: (projectName, stylesheetId, url) ->
    @allBrowsers().forEach (browser) ->
      browser.stylesheetRendered(stylesheetId, url) if browser.projectName == projectName


exports.Manager = Manager
exports.Browser = Browser


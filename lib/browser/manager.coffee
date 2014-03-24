WebSocketServer     = require('websocket').server
WebSocketConnection = require('websocket').connection
logger              = require '../support/logger'
helpers             = require '../support/helpers'
{EventEmitter}      = require 'events'
_                   = require 'underscore'

Browser             = require './browser'

class Manager extends EventEmitter
  constructor: (@options={}) ->
    @logger          = @options.logger || logger.silentLogger()
    @webServer       = @options.webServer

    @browsers        = {}
    if !@webServer
      throw 'BrowserManager not instantiated with correct options'

  watchedStylesheetsForProject: ->

  addBrowser: (browser) ->
    @logger.info "browser connected to project #{browser.projectName}"

    helpers.pipeEvent('stylesheet:resolve', browser, @)
    helpers.pipeEvent('stylesheet:listen', browser, @)

    @browsers[browser.id] = browser

    browser.connection.on 'close', =>
      @logger.info "browser disconnected from project", browser.projectName 
      browser.connection.removeAllListeners()
      delete @browsers[browser.id]

  start: ->
    @websocketServer = new WebSocketServer(
      httpServer            : @webServer
      autoAcceptConnections : false
    )

    @websocketServer.on 'request', (request) =>
      return unless request.resourceURL.pathname == '/browser'
      return unless request.resourceURL.query.project_name

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


module.exports = Manager

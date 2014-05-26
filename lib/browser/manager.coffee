# A `Manager` instance manages a pool of browsers, generally it will forward
# all messages emitted by the `Browser` instances it manages to its listeners

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

  # add a browser to the internal model
  addBrowser: (browser) ->
    @logger.info "browser connected to project #{browser.projectName}"

    helpers.pipeEvent('stylesheet:resolve', browser, @)
    helpers.pipeEvent('stylesheet:listen', browser, @)

    @browsers[browser.id] = browser

    # remove the browser from the model when it emits a `close` message
    browser.connection.on 'close', =>
      @logger.info "browser disconnected from project", browser.projectName 
      browser.connection.removeAllListeners()
      delete @browsers[browser.id]

  start: ->
    # start a web socket server
    @websocketServer = new WebSocketServer(
      httpServer            : @webServer
      autoAcceptConnections : false
    )

    # websocket endpoint `/browser?project_name=:project_name` to request a connection to a project.
    @websocketServer.on 'request', (request) =>
      return unless request.resourceURL.pathname == '/browser'
      return unless request.resourceURL.query.project_name

      connection            = request.accept()

      # normalise the incomming message format
      connection.on 'message', (message) ->
        message = if message.binaryData
          JSON.parse(message.binaryData.toString())
        else if message.utf8Data
          JSON.parse(message.utf8Data)

        @emit 'message:parsed', message

      # send messages in the appropriate format  
      connection.sendMessage = (event, data) ->
        @sendUTF JSON.stringify(
          event : event
          data  : data
        )

      # create and add a new `Browser` instance for the connection
      @addBrowser new Browser(
        connection  : connection
        projectName : request.resourceURL.query.project_name
        logger      : @logger
      )

  stop: ->
  
  # returns the list of currently connected `Browser` instances
  allBrowsers: ->
    _.values(@browsers)

  # returns an array of `stylesheetId` representing all watched stylesheets for the given project name
  watchedStylesheetsForProject: (name) ->
    stylesheets = []
    @allBrowsers().forEach (browser) ->
      stylesheets = stylesheets.concat(browser.watchedStylesheets)
    stylesheets

  # notifies browsers that a stylesheet had been rendered
  stylesheetRendered: (projectName, stylesheetId, url) ->
    @allBrowsers().forEach (browser) ->
      browser.stylesheetRendered(stylesheetId, url) if browser.projectName == projectName


module.exports = Manager

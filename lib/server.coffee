# ## Takana Server
#
# A `Server` instance is the root object in a Takana procces. It
# is reposible for starting the HTTP server, `editor.Manager` and `browser.Manager`.

helpers         = require './support/helpers'
renderer        = require './renderer'
log             = require './support/logger'
editor          = require './editor'
browser         = require './browser'
connect         = require 'connect'
http            = require 'http'
shell           = require 'shelljs'
path            = require 'path'
express         = require 'express'
livestyles      = require './livestyles'


# configuration options
Config = 
  editorPort:  48627
  httpPort:    48626
  rootDir:     helpers.sanitizePath('~/.takana/')
  scratchPath: helpers.sanitizePath('~/.takana/scratch')

class Server
  constructor: (@options={}) ->
    @logger = @options.logger || log.getLogger('Server')

    @options.editorPort   ?= Config.editorPort
    @options.rootDir      ?= Config.rootDir
    @options.httpPort     ?= Config.httpPort
    @options.scratchPath  ?= Config.scratchPath

    if (!@options.path)
      throw('specify a project path')


    app         = express()
    @webServer  = http.createServer(app)

    # the [Editor Manager](editor/manager.html) manages the editor TCP socket.
    @editorManager = new editor.Manager(
      port   : @options.editorPort
      logger : log.getLogger('EditorManager')
    )

    # the [Browser Manager](browser/manager.html) manages the browser websocket connections.
    @browserManager = new browser.Manager(
      webServer : @webServer
      logger    : log.getLogger('BrowserManager')
    )

    # the [Project Manager](livestyles/project_manager.html) connects the editor and browsers together. 
    # Live compilation happens here
    @project = new livestyles.Project(
      path           : @options.path
      name           : 'default'
      includePaths   : (@options.includePaths || [])
      scratchPath    : @options.scratchPath
      browserManager : @browserManager
      editorManager  : @editorManager
      logger         : log.getLogger("Project[#{options.name}]")#log.getLogger("Project[#{options.name}]")
    )

    # serve the client side JS for browsers that listen to live updates
    app.use express.static(path.join(__dirname, '..', '/node_modules/takana-client/dist'))
    app.use express.json()
    app.use express.urlencoded()

    app.use (req, res, next) =>
      res.setHeader 'X-Powered-By', 'Takana'
      next()

    app.use (req, res, next) =>
      @logger.trace "[#{req.socket.remoteAddress}] #{req.method} #{req.headers.host} #{req.url}"
      next()


    # returns the latest sourcemap for a stylesheet
    app.get '/livestyles/maps/:stylesheet.map', (req, res) =>
      stylesheet  = req.params.stylesheet
      href        = req.query.href

      @logger.error('**********')
      @logger.error(stylesheet)


      if sourceMap = @project.getStylesheetRender(stylesheet).sourceMap
        
        console.log('sourceMap')

        # body = helpers.absolutizeUrls(body, href) if href

        res.setHeader 'Content-Type', 'application/octet-stream'
        res.setHeader 'Content-Length', Buffer.byteLength(sourceMap)
        res.end(sourceMap)
      else
        res.end("couldn't find a sourceMap for stylesheet: #{stylesheet}")


    # returns the latest css body for a stylesheet
    app.get '/livestyles/:stylesheet.css', (req, res) =>
      stylesheet  = req.params.stylesheet
      href        = req.query.href

      if body = @project.getStylesheetRender(stylesheet).body
        
        body = helpers.absolutizeUrls(body, href) if href

        res.setHeader 'Content-Type', 'text/css'
        res.setHeader 'Content-Length', Buffer.byteLength(body)
        res.end(body)
      else
        res.end("couldn't find a body for stylesheet: #{stylesheet}")


  start: (callback) ->
    @editorManager.start()
    @browserManager.start()
    @project.start()

    shell.mkdir('-p', @options.rootDir)
    shell.mkdir('-p', @options.scratchPath)

    @webServer.listen @options.httpPort, =>
      @logger.info "webserver listening on #{@options.httpPort}"
      callback?()

  stop: (callback) ->
    @project.stop()
    @editorManager.stop =>
      @webServer.close ->
        callback?()


module.exports = Server

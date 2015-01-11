# ## Takana Server
#
# A `Server` instance is the root object in a Takana procces. It
# is reposible for starting the HTTP server, `editor.Manager` and `browser.Manager`.

helpers         = require './support/helpers'
renderer        = require './renderer'
log             = require './support/logger'
editor          = require './editor'
browser         = require './browser'
watcher         = require './watcher'
middleware      = require './support/middleware'
connect         = require 'connect'
http            = require 'http'
shell           = require 'shelljs'
path            = require 'path'
express         = require 'express'
_               = require 'underscore'

# configuration options
Config = 
  editorPort:  48627
  httpPort:    48626
  scratchPath: helpers.sanitizePath('~/.takana/scratch')

class Server
  constructor: (@options={}) ->
    @logger = @options.logger || log.getLogger('Server')

    @options.editorPort   ?= Config.editorPort
    @options.httpPort     ?= Config.httpPort
    @options.scratchPath  ?= Config.scratchPath
    @options.includePaths ?= []

    @projectName = 'default'

    if (!@options.path)
      throw('specify a project path')


    @app         = express()
    @webServer  = http.createServer(@app)

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

    @folder      = new watcher.Folder(
      path        : @options.path
      scratchPath : @options.scratchPath
      extensions  : ['sass', 'scss', 'css']
      logger      : @logger
    ) 

    @setupWebServer()
    @setupListeners()
  
  setupWebServer: ->
    # serve the client side JS for browsers that listen to live updates
    @app.use express.static(path.join(__dirname, '..', '/node_modules/takana-client/dist'))
    @app.use express.json()
    @app.use express.urlencoded()

    @app.use (req, res, next) =>
      res.setHeader 'X-Powered-By', 'Takana'
      next()

    @app.use (req, res, next) =>
      @logger.trace "[#{req.socket.remoteAddress}] #{req.method} #{req.headers.host} #{req.url}"
      next()

    @app.use middleware.absolutizeCSSUrls
    @app.use '/live', express.static(@options.scratchPath)

  setupListeners: ->
    @folder.on 'updated', => @handleFolderUpdate()

    @editorManager.on 'buffer:update', (data) =>
      return unless data.path.indexOf(@options.path) == 0
      
      @logger.debug 'processing buffer:update', data.path
      @folder.bufferUpdate(data)

    @editorManager.on 'buffer:reset', (data) =>
      return unless data.path.indexOf(@options.path) == 0
      
      @logger.debug 'processing buffer:reset', data.path
      @folder.bufferClear(data.path)

    @browserManager.on 'stylesheet:resolve', (data, callback) =>
      match = helpers.pickBestFileForHref(data.href, _.keys(@folder.files))
      if typeof(match) == 'string'
        @logger.info 'matched', data.href, '---->', match
        callback(null, match) 
      else
        callback("no match for #{data.href}") 
        @logger.warn "couldn't find a match for", data.href, match || ''

    @browserManager.on 'stylesheet:listen', (data) =>
      @logger.debug 'processing stylesheet:listen', data.id
      @handleFolderUpdate()

  handleFolderUpdate: (stats={}) ->
    @resultCache       ?= {}
    watchedStylesheets = @browserManager.watchedStylesheetsForProject(@projectName)
    
    watchedStylesheets.forEach (p) =>
      return if !p

      file = @folder.getFile(p)
      if file
        renderer.for(file.scratchPath).render {
          file         : file.scratchPath, 
          includePaths : @options.includePaths
          writeToDisk  : true
        }, (error, result) =>
          if !error
            @logger.info 'rendered', file.path
            @browserManager.stylesheetRendered(@projectName, file.path, "live/#{path.relative(@options.scratchPath, result.cssFile)}")
          else
            @logger.warn 'error rendering', file.scratchPath, ':', error
      else
        @logger.warn "couldn't find a file for watched stylesheet", path


  start: (callback) ->
    shell.mkdir('-p', @options.scratchPath)

    @editorManager.start()
    @browserManager.start()
    @folder.start =>
      callback?()
      
    @webServer.listen @options.httpPort, =>
      @logger.info "webserver listening on #{@options.httpPort}"

  stop: (callback) ->
    @folder.stop()
    @editorManager.stop =>
      @webServer.close ->
        callback?()

module.exports = Server

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

class Core
  constructor: (@options={}) ->
    @logger = log.getLogger('Core')
    app     = express()

    app.use express.static(path.join(__dirname, '..', '/www'))
    app.use express.bodyParser()
    app.use (req, res, next) =>
      @logger.trace "[#{req.socket.remoteAddress}] #{req.method} #{req.headers.host} #{req.url}"
      next()


    app.get '/projects/:name/:stylesheet', (req, res) =>
      projectName = req.params.name
      stylesheet  = req.params.stylesheet
      href        = req.query.href

      project     = @projectManager.get(projectName)
      

      if project && body = project.getBodyForStylesheet(stylesheet)
        
        body = helpers.absolutizeUrls(body, href) if href

        res.setHeader 'Content-Type', 'text/css'
        res.setHeader 'Content-Length', Buffer.byteLength(body)
        res.end(body)
      else
        res.end("couldn't find a body for stylesheet: #{stylesheet}")


    app.delete '/projects/:name', (req, res) =>
      name = req.params.name
      if @projectManager.get(name)
        @projectManager.remove name
        res.statusCode = 201
        res.end()
      else
        res.statusCode = 404
        res.setHeader('Content-Type', 'application/json')
        res.end(JSON.stringify(error: "no project named '#{name}'"))

    app.post '/projects', (req, res) =>
      name = req.body.name
      if !@projectManager.get(name)
        @projectManager.add(
          name: name
          path: req.body.path
        )
        res.statusCode = 201
        res.end()
      else 
        res.statusCode = 409
        res.setHeader('Content-Type', 'application/json')
        res.end(JSON.stringify(error: "a project named '#{name}' already exists"))

    app.get '/projects', (req, res) =>
      data = @projectManager.allProjects().map (p) -> {name: p.name, path: p.path}

      res.setHeader('Content-Type', 'application/json')
      res.end(JSON.stringify(data))

    @webServer      = http.createServer(app)

    @editorManager = new editor.Manager(
      port   : @options.editorPort
      logger : log.getLogger('EditorManager')
    )

    @browserManager = new browser.Manager(
      webServer : @webServer
      logger    : log.getLogger('BrowserManager')
    )

    @projectManager = new livestyles.ProjectManager(
      browserManager : @browserManager
      editorManager  : @editorManager
      scratchPath    : @options.scratchPath
    )

    @projectManager.add(
      name: 'worldpay-backend'
      path: '/Users/barnaby/Dropbox/Projects/worldpay-backend'
    )

  start: ->
    @logger.info "starting up..."
    @editorManager.start()
    @browserManager.start()

    shell.mkdir('-p', @options.scratchPath)

    @webServer.listen @options.httpPort, =>
      @logger.info "webserver listening on #{@options.httpPort}"


module.exports = Core
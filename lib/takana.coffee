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

class Takana
  constructor: (@options={}) ->
    @logger = log.getLogger('Core')
    app     = express()

    app.use(express.static(path.join(__dirname, '..', '/www')));

    app.get '/project/:project_name/:stylesheet', (req, res) =>
      projectName = req.params.project_name
      stylesheet  = req.params.stylesheet
      href        = req.query.href

      project     = @projectManager.get(projectName)
      
      @logger.debug "GET ", req.path

      if project && body = project.getBodyForStylesheet(stylesheet)
        
        body = helpers.absolutizeUrls(body, href) if href

        res.setHeader 'Content-Type', 'text/css'
        res.setHeader 'Content-Length', Buffer.byteLength(body)
        res.end(body)
      else
        res.end("couldn't find a body for stylesheet: #{stylesheet}")

    app.post '/projects', (req, res) =>

    app.get '/projects', (req, res) =>

    app.delete '/projects/:id', (req, res) =>

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


exports.Core = Takana
exports.helpers = helpers

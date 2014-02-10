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
Project         = require './project'



config = 
  editor_port    : 48627
  webserver_port : 48626
  scratch_path   : helpers.sanitizePath('~/.takana/scratch')


shell.mkdir('-p', config.scratch_path)

class Takana
  constructor: (@options={}) ->

    @projects = {}

    @logger = log.getLogger('Core')

    @editorManager = new editor.Manager(
      port   : config.editor_port
      logger : log.getLogger('EditorManager')
    )

    app             = express()


    app.use(express.static(path.join(__dirname, '..', '/www')));

    app.get '/project/:project_name/:stylesheet', (req, res) =>
      projectName = req.params.project_name
      stylesheet  = req.params.stylesheet
      href        = req.query.href

      project     = @getProject(projectName)
      body        = project.getBodyForStylesheet(stylesheet)
      
      if body
        if href
          body = helpers.absolutizeUrls(body, href)

        res.setHeader 'Content-Type', 'text/css'
        res.setHeader 'Content-Length', Buffer.byteLength(body)
        res.end(body)
      else
        res.end("couldn't find a body for stylesheet: #{stylesheet}")


    @webServer      = http.createServer(app)

    @browserManager = new browser.Manager(
      webServer : @webServer
      logger    : log.getLogger('BrowserManager')
    )


  addProject: (options={}) ->
    @logger.debug 'adding project', options

    project = new Project(
      path           : options.path
      name           : options.name
      scratchPath    : path.join(config.scratch_path, options.path)
      browserManager : @browserManager
      editorManager  : @editorManager
      logger         : log.getLogger("Project[#{options.name}]")
    )
    project.start()
    @projects[project.name] = project
    
  getProject: (name) -> @projects[name]

  start: ->
    @logger.info "starting up..."
    @editorManager.start()
    @browserManager.start()

    @webServer.listen config.webserver_port, =>
      @logger.info "webserver listening on #{config.webserver_port}"


exports.Core = Takana


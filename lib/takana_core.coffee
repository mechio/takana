helpers         = require './support/helpers'
renderer        = require './renderer'
log             = require './support/logger'
EditorManager   = require './editor_manager'
BrowserManager  = require './browser_manager'
connect         = require 'connect'
http            = require 'http'
shell           = require 'shelljs'



# supportDir      = helpers.sanitizePath('~/.takana')
# projectIndexDir = helpers.sanitizePath('~/.takana/projects')
# scratchDir      = helpers.sanitizePath('~/.takana/scratch')

# shell.mkdir('-p', supportDir)
# shell.mkdir('-p', projectIndexDir)
# shell.mkdir('-p', scratchDir)

# helpers.resolveSymlinksInDirectory projectIndexDir, ->
#   console.log arguments

config = 
  editor_port    : 48627
  webserver_port : 48626

logger = log.getLogger('Core')


editorManager = new EditorManager(
  port   : config.editor_port
  logger : log.getLogger('EditorManager')
)

editorManager.on 'buffer:update', ->
  logger.info arguments

editorManager.on 'buffer:reset', ->
  logger.info arguments


webServer      = http.createServer(connect())

browserManager = new BrowserManager(
  webServer : webServer
  logger    : log.getLogger('BrowserManager')
)

browserManager.on 'stylesheet:listen', (projectName, stylesheetPath, browser) ->
  callback

browserManager.on 'stylesheet:resolve', (projectName, stylesheetHref, callback) ->
  callback

exports.start = ->
  logger.info "starting up..."
  editorManager.start()
  browserManager.start()

  webServer.listen config.webserver_port, ->
    logger.info "webserver listening on #{config.webserver_port}"


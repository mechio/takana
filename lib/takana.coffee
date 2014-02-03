helpers         = require './support/helpers'
renderer        = require './renderer'
log             = require './support/logger'
editor          = require './editor'
browser         = require './browser'
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


editorManager = new editor.Manager(
  port   : config.editor_port
  logger : log.getLogger('EditorManager')
)

editorManager.on 'buffer:update', ->
  logger.info arguments

editorManager.on 'buffer:reset', ->
  logger.info arguments


webServer      = http.createServer(connect())

browserManager = new browser.Manager(
  webServer : webServer
  logger    : log.getLogger('BrowserManager')
)

browserManager.on 'stylesheet:resolve', (data, callback) =>
  console.log "GOT RESOLVE REQUEST", data.project_name, data
  id = 'BARNABY-' + data.href
  callback?(id)


browserManager.on 'stylesheet:listen', (data) =>
  console.log "Got listen event", data
  setTimeout ->
    browserManager.stylesheetRendered(data.project_name, data.id, '/path/tp/some.css')
  , 500

# browserManager.on 'stylesheet:resolve', (projectName, stylesheetHref, callback) ->
#   callback

# browserManager.watchedStylesheetsForProject('some project')
# browserManager.nofifyBrowsersOfRender

exports.start = ->
  logger.info "starting up..."
  editorManager.start()
  browserManager.start()

  webServer.listen config.webserver_port, ->
    logger.info "webserver listening on #{config.webserver_port}"


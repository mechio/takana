
helpers         = require './helpers'
renderer        = require './renderer'
log             = require './logger'
EditorManager   = require './editor_manager'
shell           = require 'shelljs'



supportDir      = helpers.sanitizePath('~/.takana')
projectIndexDir = helpers.sanitizePath('~/.takana/projects')
scratchDir      = helpers.sanitizePath('~/.takana/scratch')

# shell.mkdir('-p', supportDir)
# shell.mkdir('-p', projectIndexDir)
# shell.mkdir('-p', scratchDir)

# helpers.resolveSymlinksInDirectory projectIndexDir, ->
#   console.log arguments




logger = log.getLogger('Core')


editorManager = new EditorManager(
  port   : 48627
  logger : log.getLogger('EditorManager')
)

editorManager.on 'buffer:update', ->
  logger.info arguments


editorManager.on 'buffer:clear', ->
  logger.info arguments

exports.start = ->
  logger.info "starting up..."
  editorManager.start()

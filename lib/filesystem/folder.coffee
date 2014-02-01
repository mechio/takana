# {Config}          = require '../config'
# {Schema}          = require 'jugglingdb'
# Q                 = require 'Q'
# _                 = require 'underscore'
# glob              = require 'glob'
# path              = require 'path'
# util              = require '../util/util'
# {SassTemplate}    = require './sass_template'
# {CssTemplate}     = require './css_template'
# {LessTemplate}    = require './less_template'
# mkdirp            = require 'mkdirp'
# log4js            = require 'log4js'
# Step              = require 'step'
fsevents          = require 'fsevents'
# {EventEmitter2}   = require 'eventemitter2'
# fs                = require 'fs'
# minimatch         = require 'minimatch'
# templateFactory   = require './template_factory'
# pow               = require '../util/pow'



Template          = require './file'
{exec}            = require 'child_process'
shell             = require 'shelljs'
helpers           = require '../helpers'
Q                 = require 'q'
glob              = require 'glob'
class Folder 
  constructor: (@options={}) ->
    @files          = {}
    @name           = @options.name
    @path           = @options.path
    @scratchPath    = @options.scratchPath
    @extensions     = @options.extensions

    if !@name || !@path || !@scratchPath
      throw('Folder not instantiated with required options')

  addTemplate: (template) ->
    @templates[template.path] = template

  removeTemplate: (template) ->
    if template = @templates[template.path]
      template.removeAllListeners()
      delete @templates[template.path]

  runRsync: (callback) ->
    source      = helpers.sanitizePath(@path)
    destination = @scratchPath
    includes    = @extensions.map( (ext) -> "--include='*.#{ext}'").join(' ')
    cmd         = "rsync -arq --delete --copy-links --exclude='node_modules/' --exclude='.git' --include='+ */' #{includes} --exclude='- *' '#{source}' '#{destination}'"

    exec cmd, (error, stdout, stderr) =>
      callback?(error)

  syncToScratch: (callback) ->
    logger = @logger
    @runRsync =>
      templates = _.select _.values(@templates), (s) -> s.get('hasBuffer')
      if templates.length == 0
        callback?(null)
        return
      logger.trace "syncing buffered templates with ramdisk..." 
      timer = util.measureTime()
      Step( 
        ->
          templates.forEach (template) =>
            template.syncToRamdisk @parallel()
        , (error) ->
          if error
            logger.error "error while syncing to ramdisk: #{error}" 
          else
            logger.trace "ramdisk sync done in #{timer.elapsed()}ms"
          callback?(error)
      )



  startWatching: ->
    console.log "Watching"
    @watcher  = fsevents(@path)

    @watcher.on 'change', (path, info) =>
      event = info.event
      event = 'deleted' if event == 'moved-out'
      event = 'created' if event == 'moved-in'

      # console.log "HHHH", path
      # @_handleFSEvent(event, path, info)

  stop: ->
    if @watcher
      @watcher.removeAllListeners()
      delete @watcher

  start: (callback) ->
    shell.mkdir('-p', @scratchPath)
    @runRsync =>
      @startWatching()


      callback?()


  _handleFSEvent: (event, path, info={}) ->
    if path == @path && event == 'deleted'
      @logger.warn "project removed from filesystem"
      @stopWatching()
      @destroy()
      return

    if util.isFileOfType(path, Config.extensions.template)          
      @logger.trace "received fsevent:#{event}", path

      if event == 'deleted'
        if template = @templates[path]
          @removeTemplate(template)
      else
        if template = @templates[path]
          template.clearBuffer()


      @throttledSyncForUpdate()


    else if event == 'deleted' && info.type == 'directory'
      for k, v of @templates
        if k.indexOf(path) == 0
          @removeTemplate(v)




module.exports = Folder
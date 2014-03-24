fsevents          = require 'fsevents'
File              = require './file'
{exec}            = require 'child_process'
shell             = require 'shelljs'
helpers           = require '../support/helpers'
Q                 = require 'q'
path              = require 'path'
{EventEmitter}    = require 'events'
_                 = require 'underscore'
logger            = require '../support/logger'

class Folder extends EventEmitter
  constructor: (@options={}) ->
    @files          = {}
    @path           = @options.path
    @scratchPath    = @options.scratchPath
    @extensions     = @options.extensions
    @logger         = @options.logger || logger.silentLogger()

    @throttledEmitUpdateMessage = _.throttle @emitUpdateMessage.bind(@), 100

    if !@path || !@scratchPath || !@extensions
      throw('Folder not instantiated with required options')

  addFile: (filePath) ->
    @files[filePath] = new File(
      path:         filePath
      scratchPath:  filePath.replace(@path, @scratchPath)
    )

  removeFile: (filePath) ->
    shell.rm @files[filePath].scratchPath
    delete @files[filePath]


  getFile: (path) ->
    @files[path]

  emitUpdateMessage: ->
    @emit 'updated', @

  runRsync: (callback) ->
    source      = helpers.sanitizePath(@path)
    destination = @scratchPath
    includes    = @extensions.map( (ext) -> "--include='*.#{ext}'").join(' ')
    cmd         = "rsync -arq --delete --copy-links --exclude='node_modules/' --exclude='.git' --include='+ */' #{includes} --exclude='- *' '#{source}' '#{destination}'"
    @logger.debug 'starting rsync'
    exec cmd, (error, stdout, stderr) =>
      @logger.debug 'rsync finished'
      callback?(error)

  start: (callback) ->
    shell.mkdir('-p', @scratchPath)
    @logger.debug 'Staring...'
    @runRsync =>
      helpers.fastFind @path, @extensions, (e, files) =>
        files.forEach @addFile.bind(@)
        @startWatching()
        @logger.debug 'started'
        callback?()

  stop: ->
    if @watcher
      @watcher.stop()
      @watcher.removeAllListeners()
      delete @watcher

  bufferUpdate: (path, buffer, callback) ->
    if file = @getFile(path)
      file.updateBuffer(buffer)
      file.syncToScratch =>
        @emitUpdateMessage()
        callback?()

    else
      callback?()
    

  bufferClear: (path, callback) ->
    if file = @getFile(path)
      file.clearBuffer()
      file.syncToScratch(callback)

      @emitUpdateMessage()
    else
      callback?()

  startWatching: ->
    @watcher  = fsevents(@path)

    @watcher.on 'change', (path, info) =>
      event = info.event
      event = 'deleted' if event == 'moved-out'
      event = 'created' if event == 'moved-in'

      @_handleFSEvent(event, path, info)

  _handleFSEvent: (event, path, info={}) ->
    @logger.trace 'processing fsevent:', event, path, info
    
    if path == @path && event == 'deleted'
      @stop()
      @emit 'deleted', @
      return

    if helpers.isFileOfType(path, @extensions)          
      switch event
        when 'deleted'
          @removeFile(path) if !!@getFile(path) 

        when 'created'
          file = @addFile(path)
          file.syncToScratch()

        when 'modified'
          if file = @getFile(path) 
            file.clearBuffer()          
            file.syncToScratch()

    else if event == 'deleted' && info.type == 'directory'
      for k, v of @files
        if k.indexOf(path) == 0
          @removeFile(k)

    else
      return

    @throttledEmitUpdateMessage()


module.exports = Folder

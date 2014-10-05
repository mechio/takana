chokidar          = require 'chokidar'
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

  emitUpdateMessage: (data={}) ->
    @emit 'updated', data

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
    @watcher.close() if @watcher

  bufferUpdate: (data, callback) ->
    if file = @getFile(data.path)
      file.updateBuffer(data.buffer)
      file.syncToScratch =>
        @emitUpdateMessage(
          file:      data.path
          timestamp: data.timestamp
        )
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
    @watcher = chokidar.watch(@path,
      ignoreInitial : true
      persistent    : true
      usePolling    : false
      useFSEvents    : true      
    )

    @watcher
      .on( 'add',       (path) => @_handleFSEvent('created', path) )
      .on( 'addDir',    (path) => @_handleFSEvent('created', path, type: 'directory') )
      .on( 'change',    (path) => @_handleFSEvent('modified', path) )
      .on( 'unlink',    (path) => @_handleFSEvent('deleted', path) )
      .on( 'unlinkDir', (path) => @_handleFSEvent('deleted', path, type: 'directory') )
      .on( 'error',     (error) => console.error 'fs watch error:', error )
  
  _handleFSEvent: (event, path, info={}) ->
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

    @logger.trace 'processed fsevent:', event, path, info
    @throttledEmitUpdateMessage()


module.exports = Folder

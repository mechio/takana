logger     = require './support/logger'
watcher    = require './watcher'
renderer   = require './renderer'

class Project
  constructor: (@options={}) ->
    @path           = @options.path
    @name           = @options.name
    @scratchPath    = @options.scratchPath
    @editorManager  = @options.editorManager
    @browserManager = @options.browserManager

    if !@path || !@name || !@scratchPath || !@browserManager || !@editorManager
      throw('Project not instantiated with required options')


    @logger      = @options.logger || logger.silentLogger()
    @folder      = new watcher.Folder(
      path        : @path
      scratchPath : @scratchPath
      extensions  : ['scss', 'css']
    ) 

    @folder.on 'updated', @handleFolderUpdate.bind(@)

    @editorManager.on 'buffer:update', (data) =>
      return unless data.path.indexOf(@path) == 0
      @logger.debug 'processing buffer:update', data.path
      @folder.bufferUpdate(data.path, data.buffer)

    @editorManager.on 'buffer:reset', =>
      return unless data.path.indexOf(@path) == 0
      @logger.debug 'processing buffer:reset', data.path
      @folder.bufferClear(data.path)

    @browserManager.on 'stylesheet:resolve', (data, callback) =>
      return unless data.project_name == @name
      @logger.debug 'processing stylesheet:resolve', data.href
      callback('BARNABY-' + data.href)

    @browserManager.on 'stylesheet:listen', (data) =>
      return unless data.project_name == @name
      @logger.debug 'processing stylesheet:listen', data.id
      # console.log "Got listen event", data
      # setTimeout =>
      #   @browserManager.stylesheetRendered(data.project_name, data.id, '/path/tp/some.css')
      # , 500

  handleFolderUpdate: ->
    @logger.error 'processing folder update event'

  start: (callback) ->
    @logger.debug 'starting'
    @folder.start ->
      callback?()

  stop: ->
    @folder.stop()

module.exports = Project


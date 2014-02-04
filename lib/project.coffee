logger     = require './support/logger'
watcher    = require './watcher'
renderer   = require './renderer'
helpers    = require './support/helpers'
_          = require 'underscore'


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

      if match = helpers.pickBestFileForHref(data.href, _.keys(@folder.files))
        @logger.debug 'stylesheet', data.href, 'matched to', match
        callback(match) 
      else
        @logger.warn "coulnd't find a matching file for", data.href

    @browserManager.on 'stylesheet:listen', (data) =>
      return unless data.project_name == @name

      @logger.debug 'processing stylesheet:listen', data.id
      @handleFolderUpdate()

  handleFolderUpdate: ->
    @logger.error 'processing folder update event'

    watchedStylesheets = @browserManager.watchedStylesheetsForProject(@name)
    watchedStylesheets.forEach (path) =>
      file = @folder.getFile(path)
      if file
        @logger.debug 'rendering ', file.scratchPath
        renderer.for(file.scratchPath).render {file: file.scratchPath}, (error, body) =>
          if !error
            @browserManager.stylesheetRendered(@name, file.path, '/path/tp/some.css')
          else
            @logger.warn 'error rendering', file.scratchPath, ':', error
      else
        @logger.warn "couldn't find a file for watched stylesheet", path


  start: (callback) ->
    @logger.debug 'starting'
    @folder.start ->
      callback?()

  stop: ->
    @folder.stop()

module.exports = Project


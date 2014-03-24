logger     = require '../support/logger'
watcher    = require '../watcher'
renderer   = require '../renderer'
helpers    = require '../support/helpers'
_          = require 'underscore'


class Project
  constructor: (@options={}) ->
    @path           = @options.path
    @name           = @options.name
    @scratchPath    = @options.scratchPath
    @editorManager  = @options.editorManager
    @includePaths   = @options.includePaths 
    @browserManager = @options.browserManager
    @bodyCache      = {}

    if !@path || !@name || !@scratchPath || !@browserManager || !@editorManager
      throw('Project not instantiated with required options')

    @logger      = @options.logger || logger.silentLogger()
    @folder      = new watcher.Folder(
      path        : @path
      scratchPath : @scratchPath
      extensions  : ['scss', 'css']
      logger      : @logger
    ) 
    @bindEvents()
    
  bindEvents: ->
    @folder.on 'updated', @handleFolderUpdate.bind(@)

    @editorManager.on 'buffer:update', (data) =>
      return unless data.path.indexOf(@path) == 0
      
      @logger.debug 'processing buffer:update', data.path
      @folder.bufferUpdate(data.path, data.buffer)

    @editorManager.on 'buffer:reset', (data) =>
      return unless data.path.indexOf(@path) == 0
      
      @logger.debug 'processing buffer:reset', data.path
      @folder.bufferClear(data.path)

    @browserManager.on 'stylesheet:resolve', (data, callback) =>
      return unless data.project_name == @name

      match = helpers.pickBestFileForHref(data.href, _.keys(@folder.files))

      if typeof(match) == 'string'
        @logger.info 'matched', data.href, '---->', match
        callback(null, match) 
      else
        callback("no match for #{data.href}") 
        @logger.warn "couldn't find a match for", data.href, match || ''

    @browserManager.on 'stylesheet:listen', (data) =>
      return unless data.project_name == @name

      @logger.debug 'processing stylesheet:listen', data.id
      @handleFolderUpdate()

  handleFolderUpdate: ->
    watchedStylesheets = @browserManager.watchedStylesheetsForProject(@name)

    watchedStylesheets.forEach (path) =>
      return if !path

      file = @folder.getFile(path)
      if file
        renderer.for(file.scratchPath).render {
          file: file.scratchPath, 
          includePaths: @includePaths
        }, (error, body) =>
          if !error
            @logger.info 'rendered', file.scratchPath

            fileHash = helpers.hashCode(file.path)

            @bodyCache[fileHash] = body
            @browserManager.stylesheetRendered(@name, file.path, "projects/#{@name}/#{fileHash}")

          else
            @logger.warn 'error rendering', file.scratchPath, ':', error
      else
        @logger.warn "couldn't find a file for watched stylesheet", path

  getBodyForStylesheet: (id) ->
    @bodyCache[id]

  start: (callback) ->
    @folder.start ->
      callback?()

  stop: (callback) ->
    @folder.stop()
    callback?()

module.exports = Project


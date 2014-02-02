logger     = require './support/logger'
filesystem = require './filesystem'
renderer   = require './renderer'

class Project
  constructor: (@options={}) ->
    @path        = @options.path
    @name        = @options.name
    @scratchPath = @options.scratchPath
    @logger      = @options.logger || logger.silentLogger()
    @folder      = filesystem.Folder(
      path        : @path
      scratchPath : @scratchPath
      extensions  : ['scss', 'css']
    ) 

    @folder.on 'update', @handleFolderUpdate.bind(@)

    if !@path || !@name || !@scratchPath
      throw('Project not instantiated with required options')

  start: (callback) ->
    @folder.start ->
      callback?()

  addBrowser: (browser, stylesheet) ->
  
  handleFolderUpdate: ->
    

  stop: ->
    @folder.stop()

module.exports = Project


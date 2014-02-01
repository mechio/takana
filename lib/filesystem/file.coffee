fs               = require 'fs'
shell            = require 'shelljs'

class File
  constructor: (@options) ->
    @path         = @options.path
    @scratchPath  = @options.scratchPath
    @buffer       = null
    
  syncToScratch: (callback) ->
    if @hasBuffer()
      fs.writeFile @scratchPath, @buffer, {flags: 'w'}, callback
    else
      shell.cp '-f', @path, @scratchPath
      callback?(null)

  updateBuffer: (@buffer) ->

  clearBuffer: ->
    @buffer = null

  hasBuffer: ->
    !!@buffer

module.exports = File
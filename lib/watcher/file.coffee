fs               = require 'fs'
shell            = require 'shelljs'

class File
  constructor: (options) ->
    @optiosn      = options
    @path         = @options.path
    @scratchPath  = @options.scratchPath
    @buffer       = null
    
  syncToScratch: (callback) ->
    if @hasBuffer()
      fs.writeFile @scratchPath, @buffer, {flags: 'w'}, callback
    else
      shell.cp '-f', @path, @scratchPath
      if callback
        callback(null)

  updateBuffer: (buffer) ->
    @buffer = buffer

  clearBuffer: ->
    @buffer = null

  hasBuffer: ->
    !!@buffer

module.exports = File
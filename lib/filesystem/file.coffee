fs               = require 'fs'

class File
  constructor: (@options) ->
    @path         = @options.path
    @scratchPath  = @options.scratchPath
    @buffer       = null
    
  syncToScratchFile: (callback) ->
    if !@hasBuffer
      callback(null)
      return

    fs.writeFile @scratchFile, data, {flags: 'w'}, callback

  updateBuffer: (@buffer, callback) ->
    @syncToScratchFile callback

  clearBuffer: ->
    @buffer = null

  hasBuffer: ->
    !!@buffer

module.exports = File
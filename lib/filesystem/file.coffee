{EventEmitter}   = require 'events'
fs               = require 'fs'

class Template extends EventEmitter

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
    @syncScratchFile callback

  clearBuffer: ->
    @buffer = null

  hasBuffer: ->
    !!@buffer

  render: (options = {}, callback) ->
    # if typeof options == 'function'
    #   callback = options
    #   options  = {}

    # options.includePaths ?= []
    # if @project && @project.includePaths
    #   options.includePaths = @project.ramdiskIncludePaths()

    # timer = util.measureTime()

    # options.path = @get('ramdiskPath')

    # @_render options, (error, body) =>
    #   if error 
    #     @logger.warn "error while rendering: #{JSON.stringify(error)}"
    #     @set(
    #       lastError : error
    #     )
    #     @emit 'template.render.error', @, options
    #     callback?(error)
    #   else
    #     @logger.debug "rendered in #{timer.elapsed()}ms"
    #     @set(
    #       lastRenderedBody : body
    #       lastError        : null
    #     )
    #     @emit 'template.render.success', @, options
    #     callback?(null, body)


module.exports = Template
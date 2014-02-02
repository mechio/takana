nssocket          = require 'nssocket'
logger            = require './logger'
{EventEmitter}    = require 'events'

class EditorManager extends EventEmitter

  # send: (event, data) ->
  #   outbound = new nssocket.NsSocket()
  #   outbound.on 'start', -> outbound.send event, data
  #   outbound.on 'error', (error) ->
  #     @logger.warn "Couldn't send #{event} to editor:", error
  #   outbound.connect Config.sublimeServerPort
    
  constructor: (@options={}) ->
    @port   = @options.port || 48627
    @logger = @options.logger || logger.silentLogger()

    @server = nssocket.createServer (@socket) =>
      @logger.info "editor connected"

      @socket.data ['editor', 'reset'], @handleReset.bind(@)
      @socket.data ['editor', 'update'], @handleUpdate.bind(@)

      @socket.on 'close', ->
        @logger.warn "editor disconnected"

  start: (callback) ->
    @server.listen @port, =>
      @logger.info "editor server listening on #{@port}"
      callback?()

  stop: (callback) ->
    @server.close(callback)
    

  handleReset: (data={}) ->    
    path       = data.path
    @logger.debug "Buffer reset", path
    @emit 'buffer:reset', path : path

  handleUpdate: (data={}) ->
    if !data.path
      @logger.warn 'Regecting update (invalid format)'
      return

    path       = data.path
    buffer     = data.buffer
    timestamp  = data.created_at

    @logger.debug "Update", path    
    @emit 'buffer:update', {
      path      : path
      buffer    : buffer
      timestamp : timestamp
    }


module.exports = EditorManager
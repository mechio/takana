# The `Manager` class is a wrapper around an [nssocket](https://github.com/nodejitsu/nssocket) server.
# Through this class, editors notify the backend of changes to file buffers. 
# 
# The Sublime Text plugin maintains a single TCP socet connection accross all tabs and windows. 

nssocket          = require 'nssocket'
logger            = require '../support/logger'
{EventEmitter}    = require 'events'

class Manager extends EventEmitter
    
  constructor: (@options={}) ->
    @port   = @options.port || 48627
    @logger = @options.logger || logger.silentLogger()

    # Create an nssocket server
    @server = nssocket.createServer (@socket) =>
      @logger.info "editor connected"

      @socket.data ['editor', 'reset'], @handleReset.bind(@)
      @socket.data ['editor', 'update'], @handleUpdate.bind(@)

      @socket.on 'close', =>
        @logger.warn "editor disconnected"

  start: (callback) ->
    @server.listen @port, =>
      @logger.info "editor server listening on #{@port}"
      callback?()

  stop: (callback) ->
    @server.close(callback)
    
  # A `buffer:reset` message is emitted by the editor when changes to a file are discarded.
  handleReset: (data={}) ->    
    path       = data.path
    @logger.debug "buffer reset", path
    @emit 'buffer:reset', path : path

  # A `buffer:update` message is emitted by the editor when a file buffer is changed.
  handleUpdate: (data={}) ->
    if !data.path
      @logger.warn 'Regecting update (invalid format)'
      return

    path       = data.path
    buffer     = data.buffer
    timestamp  = data.created_at

    @logger.info "buffer updated for #{path}"
    @emit 'buffer:update', {
      path      : path
      buffer    : buffer
      timestamp : timestamp
    }


module.exports = Manager
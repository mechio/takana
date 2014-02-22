logger              = require '../support/logger'
helpers             = require '../support/helpers'
{EventEmitter}      = require 'events'


class Browser extends EventEmitter
  constructor: (@options={}) ->
    @id                 = helpers.guid()
    @logger             = @options.logger || logger.silentLogger()
    @watchedStylesheets = []
    @connection         = @options.connection
    @projectName        = @options.projectName
    
    if !@connection || !@projectName
      throw 'Browser not instantiated with correct options'

    @connection.on 'message:parsed', @handleMessage.bind(@)



  handleMessage: (message) ->
    event = message.event
    data  = message.data

    @logger.trace "received event: '#{message.event}', data:", message.data

    switch event
      when 'stylesheet:resolve'
        data.project_name ?= @projectName 
        @emit 'stylesheet:resolve', data, (error, id) =>
          data.error = error
          data.id    = id
          @connection.sendMessage 'stylesheet:resolved', data

      when 'stylesheet:listen'
        @watchedStylesheets.push data.id
        data.project_name ?= @projectName 
        @emit 'stylesheet:listen', data

  stylesheetRendered: (stylesheetId, url) ->
    @logger.trace 'sending stylesheet update to browser'

    if @watchedStylesheets.indexOf(stylesheetId) > -1
      @connection.sendMessage 'stylesheet:updated', id: stylesheetId, url: url



module.exports = Browser
# A `Browser` is a wrapper around a single websocket connection.
# web pages are notified whenever a stylesheet they reference is updated.  

# #### Browser lifecycle
# 1. browser opens web socket connection
# 2. browser sends `stylesheet:resolve` with the value of 
# 3. server sends `stylesheet:resolved` with a `stylesheetId` which uniquely identifies the stylesheet on disk.
# 4. browser sends `stylesheet:listen` with the `stylesheetId`
# 5. when any watched stylesheet is updated, the server sends `stylesheet:updated` with a `url` which points to the newly compiled css.

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
      # browsers send `stylesheet:reslove` with the value of a stylesheet `href` attribute.
      # we then call back with an id that uniquely identifies the file on disk.
      when 'stylesheet:resolve'
        data.project_name ?= @projectName 
        @emit 'stylesheet:resolve', data, (error, id) =>
          data.error = error
          data.id    = id
          @connection.sendMessage 'stylesheet:resolved', data

      # browsers send `stylesheet:listen` when they want to be notified of updates of a stylesheet
      # identified by `id`
      when 'stylesheet:listen'
        # add the stylesheet id to the set of watched stylesheets
        @watchedStylesheets.push data.id
        data.project_name ?= @projectName 

        # emit a `stylesheet:listen` to let our observers know 
        # we're watching a new stylesheet
        @emit 'stylesheet:listen', data

  # send a `stylesheet:updated` message
  stylesheetRendered: (stylesheetId, url) ->
    @logger.trace 'sending stylesheet update to browser'

    if @watchedStylesheets.indexOf(stylesheetId) > -1
      @connection.sendMessage 'stylesheet:updated', id: stylesheetId, url: url



module.exports = Browser
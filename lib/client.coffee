rest    = require 'restler'
url     = require 'url'
forever = require 'forever'
path    = require 'path'
helpers = require './support/helpers'

class Client 
  constructor: (@options={}) ->
    @url        = @options.url || 'http://localhost:48626/'
    @serverPath = @options.serverPath || path.join(__dirname, '../bin/takana-server')

  getStatus: (callback) ->
    rest.head(@url)
      .on 'complete', (data, response) ->
        if !response
          callback?(running: false)
        else
          callback?(running: (response.headers && response.headers['x-powered-by'] == 'Takana'))

  getServerProcess: (callback) ->
    forever.list false, (e, processes) =>
      callback?(forever.findByScript(@serverPath, processes))

  start: (callback) ->
    pollStatus = =>
      @getStatus (status) ->
        if status.running
          callback?(status)
        else
          setTimeout pollStatus, 5

    @getServerProcess (process) =>
      if process
        pollStatus()
        return 

      console.log "starting takana..."
      forever.startDaemon(@serverPath,
        logFile: path.join(helpers.sanitizePath('~/.takana/'), 'takana.log')
        pidFile: path.join(helpers.sanitizePath('~/.takana/'), 'takana.pid')
        max: 20
      )
      pollStatus()

  stop: ->
    @getServerProcess (process) =>
      return if !process
      console.log "stopping takana..."
      forever.stop(@serverPath)

  getProjects: (callback) ->
    rest.get(url.resolve(@url, '/projects'))
      .on('error', callback)
      .on 'success', (data, response) ->
        callback?(null, data)

  addProject: (options={}, callback) ->
    if !options.path || !options.name
      throw 'please specify path and name'

    rest.postJson(url.resolve(@url, '/projects'), options)
      .on('error', callback)
      .on 'fail', (data) -> 
        callback(data.error)
      .on 'success', (data, response) ->
        callback?()

  removeProject: (name, callback) ->
    rest.del(url.resolve(@url, "/projects/#{name}"))
      .on('error', callback)    
      .on 'fail', (data) -> 
        callback(data.error)    
      .on 'success', (data, response) ->
        callback?(null, data)


module.exports = Client

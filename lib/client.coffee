rest    = require 'restler'
url     = require 'url'
path    = require 'path'
helpers = require './support/helpers'
shell   = require 'shelljs'
class Client 
  constructor: (@options={}) ->
    @url        = @options.url || 'http://localhost:48626/'
    @serverPath = @options.serverPath || path.join(__dirname, '../bin/takana-server')
    @serverUid  = 'takana-server'

  getStatus: (callback) ->
    rest.head(@url)
      .on 'complete', (data, response) ->
        if !response
          callback?(running: false)
        else
          callback?(running: (response.headers && response.headers['x-powered-by'] == 'Takana'))

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
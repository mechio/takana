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


module.exports = Client
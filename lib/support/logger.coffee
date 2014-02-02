log4js = require('log4js')

exports.getLogger = (name) ->  
  log4js.getLogger(name)  

exports.silentLogger = ->
  {
    trace : ->
    debug : ->
    info  : ->
    warn  : ->
    error : ->
    fatal : ->
  }

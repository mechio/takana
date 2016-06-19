log4js = require('log4js')

exports.getLogger = log4js.getLogger

exports.silentLogger = ->
  {
    trace : ->
    debug : ->
    info  : ->
    warn  : ->
    error : ->
    fatal : ->
  }

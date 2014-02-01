sass         = require 'node-sass'

parseError = (errorString) ->
  error = errorString
  if matches = errorString.match(/([^\:]+)\:(\d+)\:\serror\:\s(.+)/)
    error = 
      file    : matches[1]
      line    : parseInt(matches[2])
      message : matches[3]

  error

exports.render = (options, callback) ->
  sass.render(
    file         : options.file
    includePaths : options.includePaths
    success: (body) =>
      callback?(null, body)
    error: (error) =>
      callback?(parseError(error.trim()) || error, null)
  )

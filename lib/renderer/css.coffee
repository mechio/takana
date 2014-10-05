fs           = require 'fs'

exports.render = (options, callback) ->
  fs.readFile options.file, (error, data) ->
    if error
      callback?(error, null)
    else 
      result = 
        body: data.toString()

      result.cssFile = options.file if options.writeToDisk
      callback?(null, result)
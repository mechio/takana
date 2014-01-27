fs           = require 'fs'

exports.render = (options, callback) ->
  fs.readFile options.file, (error, data) ->
    if error
      callback?(error, null)
    else 
      callback?(null, data.toString())
fs           = require 'fs'

exports.render = (options, callback) ->
  fs.readFile options.file, (error, data) ->
    if error
      if callback
      	callback(error, null)
    else 
      result = 
        body: data.toString()

      if options.writeToDisk
      	result.cssFile = options.file 
      if callback
      	callback(null, result)
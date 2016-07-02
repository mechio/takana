sass  = require 'node-sass'
path  = require 'path'
Q     = require 'q'
fs    = require 'fs'

parseError = (errorString) ->
  error = errorString
  if matches = errorString.match(/([^\:]+)\:(\d+):(.*)/)
    error = 
      file    : matches[1]
      line    : parseInt(matches[2])
      message : matches[3]

  error

exports.render = (options, callback) ->
  file            = options.file
  outFile         = options.file + '.css'
  sourceMapFile   = options.file + '.css.map'

  sass.render({
    file           : file
    includePaths   : options.includePaths
    outFile        : outFile
    sourceComments : 'map'
    sourceMap      : sourceMapFile
  }, (error, result) =>
      if(error)
          if callback
            callback(error, null)
      else
          css = result.css
          sourceMap = result.map
          if (options.writeToDisk)
            Q.nfcall(fs.writeFile, outFile, css, flags: 'w')
              .then -> Q.nfcall(fs.writeFile, sourceMapFile, sourceMap, flags: 'w')
              .then -> 
                (callback && callback(null, 
                  body      : css
                  sourceMap : sourceMap
                  cssFile   : outFile
                ))
              .fail (e) -> (callback && callback(message: error))      
              .done()
          else 
            (callback && callback(null, {
              body:      css
              sourceMap: sourceMap
            }))
  )

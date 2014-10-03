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
  stats = {}
  sass.render(
    file         : options.file
    includePaths : options.includePaths
    # sourceComments: 'map'
    sourceMap    : options.sourceMap
    stats        : stats
    success: (body) =>

      console.log('----')
      console.log('----')
      console.log('----')
      console.log('----')
      console.log('----')
      console.log('----')
      console.log('----')
      console.log('----')
      console.log('----')
      console.log('----')
      console.log('----')
      console.log('----')
      console.log('----')
      console.log('----')
      console.log('----')
      console.log('----')

      console.log(options.file)
      console.log(options.sourceMap)



      console.log(stats.sourceMap);
      console.log(body)

      callback?(null, {
        body:      body
        sourceMap: stats.sourceMap
      })
    error: (error) =>
      callback?(parseError(error.trim()) || error, null)
  )

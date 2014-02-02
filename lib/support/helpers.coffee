Q          = require('q')
fs         = require('fs')
path       = require('path')

exports.guid = ->
  "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace /[xy]/g, (c) ->
    r = Math.random() * 16 | 0
    v = (if c is "x" then r else (r & 0x3 | 0x8))
    v.toString 16

# pipes event from eventemitter a through eventemitter b
exports.pipeEvent = (event, a, b) ->
  a.on event, ->
    args = Array.prototype.slice.call(arguments)
    args.unshift(event)
    b.emit.apply(b, args)

# Given a path, returns it's extension, without the leading .
exports.extname = extname = (filePath) ->
  path.extname(filePath).replace('.', '')

# Given a file path and a extension list, 
# returns true if the file is of one of the given types 
exports.isFileOfType = isFileOfType = (p, types) ->
  types = [types] if typeof types == 'string'
  types.indexOf(extname(p)) != -1

# Given a path: 
#   1. ensures that it has a trailing slash
#   2. resolves ~ to the full path of the home directory
exports.sanitizePath = sanitizePath = (p) ->
  if (p.substr(0,1) == '~')
    p = process.env.HOME + p.substr(1)

  p = path.resolve(p)
  if /.*\/$/.test(p) then p else p + "/"

# Easily create a timer
exports.measureTime = measureTime = ->
  startTime   = Date.now()
  {
    elapsed: -> Date.now() - startTime
  }

# Given a directory, returns and resolves all symlinks
exports.resolveSymlinksInDirectory = resolveSymlinksInDirectory = (dir, callback) ->
  Q.nfcall(fs.readdir, dir)
    .then (files) ->
      # Get the stats for each file
      Q.allSettled files.map (file) ->
        Q.nfcall(fs.lstat, path.join(dir, file))
          .then (stats) ->
            stats.file = file
            stats

    .then (results) ->
      # keep the symlinks, ditch everything else
      results.filter( (result) -> result.state == 'fulfilled' && result.value.isSymbolicLink() )
             .map(    (result) -> result.value.file )

    .then (files) ->
      # resolve the symlinks
      Q.allSettled( files.map (file) ->
        Q.nfcall(fs.readlink, path.join(dir, file))
          .then (linkString) ->
            {
              linkString : linkString
              file       : file
            }
      ).then (results) -> 
        results.filter( (result) -> result.state == 'fulfilled' )
               .map(    (result) -> result.value )
        
    .then (files) ->
      callback? null, files

    .fail (error) ->
      callback?
    
    .done()
Q          = require('q')
fs         = require('fs')
path       = require('path')

# Like path.resolve, but it handles ~ expansion
exports.expandPath = (string) ->
  if (string.substr(0,1) == '~')
    string = process.env.HOME + string.substr(1)

  path.resolve(string)

# Given a path, returns it's extension, without the leading .
exports.extname = (filePath) ->
  path.extname(filePath).replace('.', '')

# Given a directory, returns and resolves all symlinks
exports.resolveSymlinksInDirectory = (dir, callback) ->
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
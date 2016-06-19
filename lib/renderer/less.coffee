less  = require 'less'
path  = require 'path'
Q     = require 'q'
fs    = require 'fs'

less.FileManager.prototype._loadFile = less.FileManager.prototype.loadFile;
less.FileManager.prototype.setTakanaPath = (rootpath) ->
    this._takanaPath = rootpath
less.FileManager.prototype.getTakanaPath = ->
    return this._takanaPath
less.FileManager.prototype.loadFile = (filename) ->
    args = arguments;
    if(!this.isPathAbsolute(filename))
        takanaPath = this.getTakanaPath()
        if(takanaPath)
          args[0] = takanaPath+path.sep+filename;
    this._loadFile.apply(this,args);

exports.render = (options, callback) ->
  file            = options.file
  outFile         = options.file + '.css'
  sourceMapConfigs   = { sourceMapFilename: options.file + '.css.map', outputFilename: options.file + '.css.map' }
  fs.readFile(file, 'utf8', (error, data) ->
      options.includePaths = [path.dirname(options.file)].concat(options.includePaths)
      rootpath = path.dirname(options.file)
      less.FileManager.prototype.setTakanaPath(rootpath)
      less.render(data, {
        rootpath       : rootpath,   
        paths          : options.includePaths
        sourceMap      : sourceMapConfigs
      }, (error, result) =>
          if(error)
              error.file = options.file;
              if callback
                callback(error, null)
          else
              css = result.css
              sourceMap = result.map
              if (options.writeToDisk)
                Q.nfcall(fs.writeFile, outFile, css, flags: 'w')
                  .then -> Q.nfcall(fs.writeFile, sourceMapConfigs.sourceMapFilename, sourceMap, flags: 'w')
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

  );

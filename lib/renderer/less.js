import less from 'less';
import path from 'path';
import Q from 'q';
import fs from 'fs';

less.FileManager.prototype._loadFile = less.FileManager.prototype.loadFile;
less.FileManager.prototype.setTakanaPath = function(rootpath) {
    return this._takanaPath = rootpath;
  };
less.FileManager.prototype.getTakanaPath = function() {
    return this._takanaPath;
  };
less.FileManager.prototype.loadFile = function(filename) {
    let args = arguments;
    if(!this.isPathAbsolute(filename)) {
        let takanaPath = this.getTakanaPath();
        if(takanaPath) {
          args[0] = takanaPath+path.sep+filename;
        }
      }
    return this._loadFile.apply(this,args);
  };

function render(options, callback) {
  let { file }            = options;
  let outFile         = options.file + '.css';
  let sourceMapConfigs   = { sourceMapFilename: options.file + '.css.map', outputFilename: options.file + '.css.map' };
  fs.readFile(file, 'utf8', (error, data) => {
      options.includePaths = [path.dirname(options.file)].concat(options.includePaths);
      let rootpath = path.dirname(options.file);
      less.FileManager.prototype.setTakanaPath(rootpath);
      less.render(data, {
        rootpath,   
        paths          : options.includePaths,
        sourceMap      : sourceMapConfigs
      }, (error, result) => {
          if (error) {
              error.file = options.file;
              if (callback) {
                return callback(error, null);
              }
          } else {
              let { css } = result;
              let sourceMap = result.map;
              if (options.writeToDisk) {
                Q.nfcall(fs.writeFile, outFile, css, {flags: 'w'})
                  .then(() => Q.nfcall(fs.writeFile, sourceMapConfigs.sourceMapFilename, sourceMap, {flags: 'w'}))
                  .then(() => 
                    callback && callback(null, { 
                      body      : css,
                      sourceMap : sourceMap,
                      cssFile   : outFile
                    }
                    )
                  )
                  .fail(e => callback && callback({message: error}))      
                  .done();
              } else { 
                (callback && callback(null, {
                  body:      css,
                  sourceMap: sourceMap
                }));
              }
            }
        }
      );
    }

  );
}

module.exports = { render: render }

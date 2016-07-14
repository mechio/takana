import sass from 'node-sass';
import path from 'path';
import Q from 'q';
import fs from 'fs';

let parseError = function(errorString) {
  let matches;
  let error = errorString;
  if (matches = errorString.match(/([^\:]+)\:(\d+):(.*)/)) {
    error = { 
      file    : matches[1],
      line    : parseInt(matches[2]),
      message : matches[3]
    };
  }

  return error;
};

function render(options, callback) {
  let { file }            = options;
  let outFile         = options.file + '.css';
  let sourceMapFile   = options.file + '.css.map';

  return sass.render({
    file,
    includePaths   : options.includePaths,
    outFile,
    sourceComments : 'map',
    sourceMap      : sourceMapFile
  }, (error, result) => {
      if(error) {
          if (callback) {
            return callback(error, null);
          }
      } else {
          let { css } = result;
          let sourceMap = result.map;
          if (options.writeToDisk) {
            return Q.nfcall(fs.writeFile, outFile, css, {flags: 'w'})
              .then(() => Q.nfcall(fs.writeFile, sourceMapFile, sourceMap, {flags: 'w'}))
              .then(() => 
                callback && callback(null, { 
                  body      : css,
                  sourceMap,
                  cssFile   : outFile
                }
                )
              )
              .fail(e => callback && callback({message: error}))      
              .done();
          } else { 
            return (callback && callback(null, {
              body:      css,
              sourceMap
            }));
          }
        }
    }
  );
}

module.exports = { render: render };

import fs from 'fs';

function render(options, callback) {
  return fs.readFile(options.file, function(error, data) {
    if (error) {
      if (callback) {
      	return callback(error, null);
    }
    } else { 
      let result = 
        {body: data.toString()};

      if (options.writeToDisk) {
      	result.cssFile = options.file; 
    }
      if (callback) {
      	return callback(null, result);
    }
    }
  });
}

module.exports = { render: render };
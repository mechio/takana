import fs from 'fs';
import shell from 'shelljs';

export default class File {
  constructor(options) {
    this.options      = options;
    this.path         = this.options.path;
    this.scratchPath  = this.options.scratchPath;
    this.buffer       = null;
  }
    
  syncToScratch(callback) {
    if (this.hasBuffer()) {
      return fs.writeFile(this.scratchPath, this.buffer, {flags: 'w'}, callback);
    } else {
      shell.cp('-f', this.path, this.scratchPath);
      if (callback) {
        return callback(null);
      }
    }
  }

  updateBuffer(buffer) {
    return this.buffer = buffer;
  }

  clearBuffer() {
    return this.buffer = null;
  }

  hasBuffer() {
    return !!this.buffer;
  }
}
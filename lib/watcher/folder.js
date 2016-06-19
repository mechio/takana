var file;
var file;
import chokidar from 'chokidar';
import File from './file';
import { exec } from 'child_process';
import shell from 'shelljs';
import helpers from '../support/helpers';
import Q from 'q';
import path from 'path';
import { EventEmitter } from 'events';
import _ from 'underscore';
import logger from '../support/logger';

class Folder extends EventEmitter {
  constructor(options) {
    super();
    this.options        = options || {};
    this.files          = {};
    this.path           = this.options.path;
    this.scratchPath    = this.options.scratchPath;
    this.extensions     = this.options.extensions;
    this.logger         = this.options.logger || logger.silentLogger();

    this.throttledEmitUpdateMessage = _.throttle(this.emitUpdateMessage.bind(this), 100);

    if (!this.path || !this.scratchPath || !this.extensions) {
      throw('Folder not instantiated with required options');
    }
  }

  addFile(filePath) {
    return this.files[filePath] = new File({
      path:         filePath,
      scratchPath:  filePath.replace(this.path, this.scratchPath)
    }
    );
  }

  removeFile(filePath) {
    shell.rm(this.files[filePath].scratchPath);
    return delete this.files[filePath];
  }


  getFile(path) {
    return this.files[path];
  }

  emitUpdateMessage(data) {
    data = data || {};
    return this.emit('updated', data);
  }

  runRsync(callback) {
    let source      = helpers.sanitizePath(this.path);
    let destination = this.scratchPath;
    let includes    = this.extensions.map( ext => `--include='*.${ext}'`).join(' ');
    let cmd         = `rsync -arq --delete --copy-links --exclude='node_modules/' --exclude='.git' --include='+ */' ${includes} --exclude='- *' '${source}' '${destination}'`;
    this.logger.debug('starting rsync');
    return exec(cmd, (error, stdout, stderr) => {
      this.logger.debug('rsync finished');
      if (callback) {
        return callback(error);
      }
    });
  }

  start(callback) {
    shell.mkdir('-p', this.scratchPath);
    this.logger.debug('Staring...');
    return this.runRsync(() => {
      return helpers.fastFind(this.path, this.extensions, (e, files) => {
        files.forEach(this.addFile.bind(this));
        this.startWatching();
        this.logger.debug('started');
        if (callback) {
          return callback();
        }
      });
    });
  }

  stop() {
    console.log('called!');
    if (this.watcher) { 
      console.log('called!!!', this.watcher);
      this.watcher.close(); 
    }
    console.log('closed');
  }

  bufferUpdate(data, callback) {
    if (file = this.getFile(data.path)) {
      file.updateBuffer(data.buffer);
      return file.syncToScratch(() => {
        this.emitUpdateMessage({
          file:      data.path,
          timestamp: data.timestamp
        }
        );
        return (callback && callback());
      });

    } else {
      if (callback) {
        return callback();
      }
    }
  }
    

  bufferClear(path, callback) {
    if (file = this.getFile(path)) {
      file.clearBuffer();
      file.syncToScratch(callback);

      return this.emitUpdateMessage();
    } else {
      if (callback) {
        return callback();
      }
    }
  }

  startWatching() {
    this.watcher = chokidar.watch(this.path, {
      ignoreInitial : true,
      persistent    : true,
      usePolling    : false,
      useFSEvents    : true      
    }
    );

    return this.watcher
      .on( 'add',       path => this._handleFSEvent('created', path) )
      .on( 'addDir',    path => this._handleFSEvent('created', path, {type: 'directory'}) )
      .on( 'change',    path => this._handleFSEvent('modified', path) )
      .on( 'unlink',    path => this._handleFSEvent('deleted', path) )
      .on( 'unlinkDir', path => this._handleFSEvent('deleted', path, {type: 'directory'}) )
      .on( 'error',     error => console.error('fs watch error:', error) );
  }
  
  _handleFSEvent(event, path, info) {
    info = info || {};
    if (path === this.path && event === 'deleted') {
      this.stop();
      this.emit('deleted', this);
      return;
    }

    if (helpers.isFileOfType(path, this.extensions)) {          
      switch (event) {
        case 'deleted':
          if (!!this.getFile(path)) { this.removeFile(path); } 
          break;

        case 'created':
          let file = this.addFile(path);
          file.syncToScratch();
          break;

        case 'modified':
          if (file = this.getFile(path)) { 
            file.clearBuffer();          
            file.syncToScratch();
          }
          break;
      }

    } else if (event === 'deleted' && info.type === 'directory') {
      for (let k in this.files) {
        let v = this.files[k];
        if (k.indexOf(path) === 0) {
          this.removeFile(k);
        }
      }

    } else {
      return;
    }

    this.logger.trace('processed fsevent:', event, path, info);
    return this.throttledEmitUpdateMessage();
  }
}


export default Folder;

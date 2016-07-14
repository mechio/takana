// The `Manager` class is a wrapper around an [nssocket](https://github.com/nodejitsu/nssocket) server.
// Through this class, editors notify the backend of changes to file buffers. 
// 
// The Sublime Text plugin maintains a single TCP socet connection accross all tabs and windows. 

import nssocket from 'nssocket';
import logger from '../support/logger';
import { EventEmitter } from 'events';

export default class Manager extends EventEmitter {
    
  constructor(options) {
    super();
    this.options = options || {};

    this.port   = this.options.port || 48627;
    this.logger = this.options.logger || logger.silentLogger();

    // Create an nssocket server
    this.server = nssocket.createServer(socket => {
      this.socket = socket;
      this.logger.info("editor connected");

      this.socket.data(['editor', 'reset'], this.handleReset.bind(this));
      this.socket.data(['editor', 'update'], this.handleUpdate.bind(this));

      return this.socket.on('close', () => {
        return this.logger.warn("editor disconnected");
      });
    });
  }

  start(callback) {
    return this.server.listen(this.port, () => {
      this.logger.info(`editor server listening on ${this.port}`);
      if (callback) {
        return callback();
      }
    });
  }

  stop(callback) {
    return this.server.close(callback);
  }
    
  // A `buffer:reset` message is emitted by the editor when changes to a file are discarded.
  handleReset(data) {
    data       = data || {};    
    let { path }       = data;
    this.logger.debug("buffer reset", path);
    return this.emit('buffer:reset', {path});
  }

  // A `buffer:update` message is emitted by the editor when a file buffer is changed.
  handleUpdate(data) {
    data       = data || {};
    if (!data.path) {
      this.logger.warn('Regecting update (invalid format)');
      return;
    }

    let { path }       = data;
    let { buffer }     = data;
    let timestamp  = data.created_at;

    this.logger.info(`buffer updated for ${path}`);
    return this.emit('buffer:update', {
      path,
      buffer,
      timestamp
    });
  }
}
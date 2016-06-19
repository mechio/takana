// A `Browser` is a wrapper around a single websocket connection.
// web pages are notified whenever a stylesheet they reference is updated.  

// #### Browser lifecycle
// 1. browser opens web socket connection
// 2. browser sends `stylesheet:resolve` with the value of 
// 3. server sends `stylesheet:resolved` with a `stylesheetId` which uniquely identifies the stylesheet on disk.
// 4. browser sends `stylesheet:listen` with the `stylesheetId`
// 5. when any watched stylesheet is updated, the server sends `stylesheet:updated` with a `url` which points to the newly compiled css.

import logger from '../support/logger';
import helpers from '../support/helpers';
import { EventEmitter } from 'events';


class Browser extends EventEmitter {
  constructor(options) {
    super()
    this.options            = options || {};
    this.id                 = helpers.guid();
    this.logger             = this.options.logger || logger.silentLogger();
    this.watchedStylesheets = [];
    this.connection         = this.options.connection;
    this.projectName        = this.options.projectName;
    
    if (!this.connection || !this.projectName) {
      throw 'Browser not instantiated with correct options';
    }

    this.connection.on('message:parsed', this.handleMessage.bind(this));
  }



  handleMessage(message) {
    let { event } = message;
    let { data }  = message;

    this.logger.trace(`received event: '${message.event}', data:`, message.data);

    switch (event) {
      // browsers send `stylesheet:reslove` with the value of a stylesheet `href` attribute.
      // we then call back with an id that uniquely identifies the file on disk.
      case 'stylesheet:resolve':
        if (data.project_name == null) { data.project_name = this.projectName; } 
        return this.emit('stylesheet:resolve', data, (error, id) => {
          data.error = error;
          data.id    = id;
          return this.connection.sendMessage('stylesheet:resolved', data);
        });

      // browsers send `stylesheet:listen` when they want to be notified of updates of a stylesheet
      // identified by `id`
      case 'stylesheet:listen':
        // add the stylesheet id to the set of watched stylesheets
        this.watchedStylesheets.push(data.id);
        if (data.project_name == null) { data.project_name = this.projectName; } 

        // emit a `stylesheet:listen` to let our observers know 
        // we're watching a new stylesheet
        return this.emit('stylesheet:listen', data);
    }
  }

  // send a `stylesheet:updated` message
  stylesheetRendered(stylesheetId, url) {
    this.logger.trace('sending stylesheet update to browser');

    if (this.watchedStylesheets.indexOf(stylesheetId) > -1) {
      return this.connection.sendMessage('stylesheet:updated', {id: stylesheetId, url});
    }
  }
}



export default Browser;
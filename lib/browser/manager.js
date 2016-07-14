// A `Manager` instance manages a pool of browsers, generally it will forward
// all messages emitted by the `Browser` instances it manages to its listeners

import { server as WebSocketServer } from 'websocket';
import { connection as WebSocketConnection } from 'websocket';
import logger from '../support/logger';
import helpers from '../support/helpers';
import { EventEmitter } from 'events';
import _ from 'underscore';
import Browser from './browser';

class Manager extends EventEmitter {
  constructor(options) {
    super();
    this.options         = options || {}; 
    this.logger          = this.options.logger || logger.silentLogger();
    this.webServer       = this.options.webServer;
    this.browsers        = {};

    if (!this.webServer) {
      throw 'BrowserManager not instantiated with correct options';
    }
  }

  // add a browser to the internal model
  addBrowser(browser) {
    this.logger.info(`browser connected to project ${browser.projectName}`);

    helpers.pipeEvent('stylesheet:resolve', browser, this);
    helpers.pipeEvent('stylesheet:listen', browser, this);

    this.browsers[browser.id] = browser;

    // remove the browser from the model when it emits a `close` message
    return browser.connection.on('close', () => {
      this.logger.info("browser disconnected from project", browser.projectName); 
      browser.connection.removeAllListeners();
      return delete this.browsers[browser.id];
    });
  }

  start() {
    // start a web socket server
    this.websocketServer = new WebSocketServer({
      httpServer            : this.webServer,
      autoAcceptConnections : false
    }
    );

    // websocket endpoint `/browser?project_name=:project_name` to request a connection to a project.
    return this.websocketServer.on('request', request => {
      if (request.resourceURL.pathname !== '/browser') { return; }
      if (!request.resourceURL.query.project_name) { return; }

      let connection            = request.accept();

      // normalise the incomming message format
      connection.on('message', function(message) {
        if (message.binaryData) {
          message = JSON.parse(message.binaryData.toString());
        } else if (message.utf8Data) {
          message = JSON.parse(message.utf8Data);
        }

        return this.emit('message:parsed', message);
      });

      // send messages in the appropriate format  
      connection.sendMessage = function(event, data) {
        return this.sendUTF(JSON.stringify({
          event,
          data
        }
        ));
      };

      // create and add a new `Browser` instance for the connection
      return this.addBrowser(new Browser({
        connection,
        projectName : request.resourceURL.query.project_name,
        logger      : this.logger
      }
      ));
    });
  }

  stop() {}
  
  // returns the list of currently connected `Browser` instances
  allBrowsers() {
    return _.values(this.browsers);
  }

  // returns an array of `stylesheetId` representing all watched stylesheets for the given project name
  watchedStylesheetsForProject(name) {
    let stylesheets = [];
    this.allBrowsers().forEach(browser => stylesheets = stylesheets.concat(browser.watchedStylesheets));
    return stylesheets;
  }

  // notifies browsers that a stylesheet had been rendered
  stylesheetRendered(projectName, stylesheetId, url) {
    return this.allBrowsers().forEach(function(browser) {
      if (browser.projectName === projectName) { return browser.stylesheetRendered(stylesheetId, url); }
    });
  }
}


export default Manager;

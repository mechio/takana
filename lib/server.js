// ## Takana Server
//
// A `Server` instance is the root object in a Takana procces. It
// is reposible for starting the HTTP server, `editor.Manager` and `browser.Manager`.

import helpers from './support/helpers';
import renderer from './renderer';
import log from './support/logger';
import editor from './editor';
import browser from './browser';
import watcher from './watcher';
import middleware from './support/middleware';
import connect from 'connect';
import http from 'http';
import shell from 'shelljs';
import path from 'path';
import express from 'express';
import _ from 'underscore';
import fs from 'fs';

// configuration options
let Config = { 
  editorPort:  48627,
  httpPort:    48626,
  scratchPath: helpers.sanitizePath('~/.takana/scratch')
};

export default class Server {
  constructor(options) {
    this.options = options || {};
    this.logger = this.options.logger || log.getLogger('Server');

    if (this.options.editorPort == null) {   this.options.editorPort = Config.editorPort; }
    if (this.options.httpPort == null) {     this.options.httpPort = Config.httpPort; }
    if (this.options.scratchPath == null) {  this.options.scratchPath = Config.scratchPath; }
    if (this.options.includePaths == null) { this.options.includePaths = []; }

    this.projectName = 'default';

    if (!this.options.path) {
      throw('specify a project path');
    }

    this.app        = express();
    this.webServer  = http.createServer(this.app);

    // the [Editor Manager](editor/manager.html) manages the editor TCP socket.
    this.editorManager = new editor.Manager({
      port   : this.options.editorPort,
      logger : log.getLogger('EditorManager')
    }
    );

    // the [Browser Manager](browser/manager.html) manages the browser websocket connections.
    this.browserManager = new browser.Manager({
      webServer : this.webServer,
      logger    : log.getLogger('BrowserManager')
    }
    );

    this.folder = new watcher.Folder({
      path        : this.options.path,
      scratchPath : this.options.scratchPath,
      extensions  : ['sass', 'scss','less', 'css'],
      logger      : this.logger
    }
    ); 

    this.setupWebServer();
    this.setupListeners();
  }
  
  setupWebServer() {
    // serve the client side JS for browsers that listen to live updates
    try {
      var takanaClientDistPath = path.join(__dirname, '../../..', '/node_modules/takana-client/dist');
      fs.accessSync(takanaClientDistPath);
    } catch (error) {
      var takanaClientDistPath = path.join(__dirname, '..', '/node_modules/takana-client/dist');
    }

    this.app.use(express.static(takanaClientDistPath));
    this.app.use(express.json());
    this.app.use(express.urlencoded());

    this.app.use((req, res, next) => {
      res.setHeader('X-Powered-By', 'Takana');
      return next();
    });

    this.app.use((req, res, next) => {
      this.logger.trace(`[${req.socket.remoteAddress}] ${req.method} ${req.headers.host} ${req.url}`);
      return next();
    });

    this.app.use(middleware.absolutizeCSSUrls);
    return this.app.use('/live', express.static(this.options.scratchPath));
  }

  setupListeners() {
    this.folder.on('updated', () => this.handleFolderUpdate());

    this.editorManager.on('buffer:update', data => {
      if (data.path.indexOf(this.options.path) !== 0) { return; }
      
      this.logger.debug('processing buffer:update', data.path);
      return this.folder.bufferUpdate(data);
    });

    this.editorManager.on('buffer:reset', data => {
      if (data.path.indexOf(this.options.path) !== 0) { return; }
      
      this.logger.debug('processing buffer:reset', data.path);
      return this.folder.bufferClear(data.path);
    });

    this.browserManager.on('stylesheet:resolve', (data, callback) => {
      let href = data.takanaHref || data.href;
      let match = helpers.pickBestFileForHref(href, _.keys(this.folder.files));

      if (typeof(match) === 'string') {
        this.logger.info('matched', href, '---->', match);
        return callback(null, match); 
      } else {
        callback(`no match for ${href}`); 
        return this.logger.warn("couldn't find a match for", href, match || '');
      }
    });

    return this.browserManager.on('stylesheet:listen', data => {
      this.logger.debug('processing stylesheet:listen', data.id);
      return this.handleFolderUpdate();
    });
  }

  handleFolderUpdate(stats={}) {
    if (this.resultCache == null) {       this.resultCache = {}; }
    let watchedStylesheets = this.browserManager.watchedStylesheetsForProject(this.projectName);
    
    return watchedStylesheets.forEach(p => {
      if (!p) { return; }

      let file = this.folder.getFile(p);
      if (file) {
        return renderer.for(file.scratchPath).render({
          file         : file.scratchPath, 
          includePaths : this.options.includePaths,
          writeToDisk  : true
        }, (error, result) => {
          if (!error) {
            this.logger.info('rendered', file.path);
            return this.browserManager.stylesheetRendered(this.projectName, file.path, `live/${path.relative(this.options.scratchPath, result.cssFile)}`);
          } else {
            return this.logger.warn('error rendering', file.scratchPath, ':', error);
          }
        });
      } else {
        return this.logger.warn("couldn't find a file for watched stylesheet", path);
      }
    });
  }


  start(callback) {
    shell.mkdir('-p', this.options.scratchPath);

    this.editorManager.start();
    this.browserManager.start();
    this.folder.start(() => {
      if (callback) {
        return callback();
      }
    });
      
    return this.webServer.listen(this.options.httpPort, () => {
      return this.logger.info(`webserver listening on ${this.options.httpPort}`);
    });
  }

  stop(callback) {
    this.folder.stop();

    this.editorManager.stop(() => {
      this.webServer.close(() => {

        if (callback) { 
          callback();
        }
      });
    });
  }
}
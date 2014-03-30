'use strict';

require("coffee-script");

var path     = require('path'),
    shell    = require('shelljs'),
    Log4js   = require('log4js'),
    logger   = Log4js.getDefaultLogger();


exports.Client  = require('./lib/client');

var Server  = exports.Server  = require('./lib/core');
var helpers = exports.helpers = require('./lib/support/helpers');

exports.run = function(options){

  options         = options || {};

  if (!options.path || !options){
    throw('not invoked with required parameters');
  }

  if (!options.verbose) {
    Log4js.setGlobalLogLevel(Log4js.levels.INFO);
    Log4js.configure({
        appenders: [
        {
          type: 'console',
          layout: {
            type: 'pattern',
            pattern: "%[[%r] [%p] - %]%m"
          }
        }
      ]
    });
  }

  var core        = new Server();

  console.log();
  console.log();
  console.log('      _        _                     ');
  console.log('     | |_ __ _| | ____ _ _ __   __ _ ');
  console.log('     | __/ _` | |/ / _` | \'_ \\ / _` |');
  console.log('     | || (_| |   < (_| | | | | (_| |');
  console.log('      \\__\\__,_|_|\\_\\__,_|_| |_|\\__,_|');
  console.log('                                     ');
  console.log();
  console.log('     Paste this snippet inside <head> to live-edit your stylesheets:');
  console.log('     <script type="text/javascript" src="http://localhost:48626/takana.js"></script>');
  console.log();
  console.log();
  core.start(function(){

    if (!options.skipSublime){
      helpers.installSublimePlugin();
    }

    logger.info('adding project folder', options.path);

    core.projectManager.add({
      name:         'default',
      path:         options.path,
      includePaths: options.includePaths
    });

  });  
}



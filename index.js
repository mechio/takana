'use strict';

require("coffee-script");

var path     = require('path'),
    shell    = require('shelljs'),
    Log4js   = require('log4js'),
    fs       = require('fs'),
    logger   = Log4js.getDefaultLogger();

var Server  = exports.Server  = require('./lib/server');
var helpers = exports.helpers = require('./lib/support/helpers');

function installSublimePlugin(){

  var takanaPackagePath = null,
      searchPaths = [
    helpers.sanitizePath('~/Library/Application Support/Sublime Text 3/Packages/'),
    helpers.sanitizePath('~/Library/Application Support/Sublime Text 2/Packages/'),
    helpers.sanitizePath('~/.config/sublime-text-3/Packages/') // linux
  ];

  searchPaths.forEach(function(p){
    if (takanaPackagePath) return;
    if (fs.existsSync(p)){
      takanaPackagePath = path.join(p, 'Takana');
    }
  });

  if (takanaPackagePath){
    logger.info("installing plugin to '%s'", takanaPackagePath);
    shell.mkdir('-p', takanaPackagePath);
    shell.cp('-f', path.join(__dirname, './sublime-plugin/takana.py'), path.join(takanaPackagePath, 'takana.py'));
  }
  else {
    logger.error("couldn't find a Sublime Text package directory. Install an editor plugin manually.");
    logger.error("search paths were:", searchPaths);
  }
}



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

  var server = new Server({
    name:         'default',
    path:         options.path,
    includePaths: options.includePaths
  });

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
  console.log();
  console.log('     <script type="text/javascript" src="http://localhost:48626/takana.js"></script>');
  console.log('     <script type="text/javascript">');
  console.log("       takanaClient.run({host: 'localhost:48626'});");
  console.log('     </script>');
  console.log();
  console.log();
  logger.warn('if you have just upgraded from version 0.0.10 or below, please update the javascript snippet (above)');
  server.start(function(){

    if (!options.skipSublime){
      installSublimePlugin();
    }

    logger.info('running on project', options.path);


  });  
}



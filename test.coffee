fsevents          = require 'fsevents'

helpers = require './lib/helpers'

@watcher  = fsevents(helpers.sanitizePath('~/tmp'))

@watcher.on 'change', (path, info) => 
  console.log path, info
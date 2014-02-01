fsevents          = require 'fsevents'

helpers = require './lib/helpers'

@watcher  = fsevents(helpers.sanitizePath('/Users/barnaby/Projects/takana-simple/tmp/testsource'))

@watcher.on 'change', (path, info) => 
  console.log path, info
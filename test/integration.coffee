Server = require '../lib/server' 
path   = require 'path'

describe 'Server', ->
  beforeEach ->
    @server = new Server({
      name:         'default',
      path:         fixturePath('foundation5'),
      scratchPath:  createEmptyTmpDir()
      includePaths: []
    });


  it 'should work for a css project', ->

  it 'should work for a foundation project', ->

    




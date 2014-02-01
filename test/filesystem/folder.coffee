Folder  = require '../../lib/filesystem/folder'
shell   = require 'shelljs'
path    = require 'path'
sinon   = require 'sinon'
glob    = require 'glob'

mockFolder = ->
  new Folder(
    name:        'test_folder'
    extensions:  ['scss', 'css']
    path:        fixturePath('filesystem/project')
    scratchPath: path.join(createEmptyTmpDir(), 'test_folder')
  )

describe 'Project', ->
  context 'on start', ->
    before (done) ->
      @folder       = mockFolder()
      @startWatching = sinon.stub(@folder, 'startWatching')
      assertFileExistance(false, @folder.scratchPath)
      @folder.start -> done()

    it 'should create its scratch folder', ->
      assertIsFolder(true, @folder.scratchPath)

    it 'should sync its watched directory to the scratch space', ->
      assertFoldersEqual('**/*.{scss,css}', @folder.path, @folder.scratchPath)

    it 'should have an accurate internal representation of the folder', (done) ->
      glob path.join(@folder.path, "**/*.{scss,css}"), (e, files) ->
        console.log files.length
        done()

    it 'should start watching its folder for changes', ->
      @startWatching.calledOnce.should.be.true

  context 'template', ->
    context 'buffer updated', ->
      it "should call in order"
      it "should update the corresponding template's buffer"
      it "should sync the dirty templates to the scratch"
      it "should publish an update event"

    context 'cleared', ->
      it "should call in order"      
      it "should clear the corresponding template's buffer"
      it "should sync the dirty templates to the scratch"   
      it "should publish an update event"

  context 'watching', ->
    before  ->
      @folder       = mockFolder()
      # @folder.start -> done()

    context 'file deleted', ->
      it "should call in order", ->
      it "should be removed from the internal representation"
      it "should be removed from the scratch"
      it "should publish an update event"

    context 'file created', ->
      it "should add it to its internal representation"
      it "should be added to the scratch"
      it "should publish an update event"

    context 'file modified', ->
      it "should sync to the scrath"
      it "should publish an update event"

    context 'folder deleted', ->
      it 'should remove', ->
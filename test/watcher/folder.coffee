Folder  = require '../../lib/watcher/folder'
shell   = require 'shelljs'
path    = require 'path'
sinon   = require 'sinon'
glob    = require 'glob'
_       = require 'underscore'
fs      = require 'fs'
Q       = require 'q'

mockFolder = ->
  source  = createEmptyTmpDir('source')
  scratch = path.join(createEmptyTmpDir(), 'scratch')

  shell.cp('-r', fixturePath('filesystem/project/*'), source)

  new Folder(
    extensions:  ['scss', 'css']
    path:        source
    scratchPath: scratch
  )

describe 'Project', ->
  before (done) ->
    @folder       = mockFolder()
    @startWatching = sinon.stub(@folder, 'startWatching')
    assertFileExistance(false, @folder.scratchPath)
    @folder.start -> done()

  beforeEach ->
    @emitStub = sinon.stub(@folder, 'emitUpdateMessage');
    # @throttledEmitUpadteStub = sinon.stub(@project, 'throttledEmitUpdateMessage')

    
  afterEach ->
    @emitStub.restore()
    # @throttledEmitUpadteStub.restore()    

  context 'on start', ->
    it 'should create its scratch folder', ->
      assertIsFolder(true, @folder.scratchPath)

    it 'should sync its watched directory to the scratch space', ->
      assertFoldersEqual('**/*.{scss,css}', @folder.path, @folder.scratchPath)

    it 'should have an accurate internal representation of the folder', (done) ->
      @folder.files.should.not.be.empty
      glob path.join(@folder.path, "**/*.{scss,css}"), (e, files) =>
        files.length.should.equal(_.keys(@folder.files).length)
        files.forEach (f) =>
          @folder.getFile(f).path.should.equal(f)

        done()

    it 'should start watching its folder for changes', ->
      @startWatching.calledOnce.should.be.true

  context 'template', ->
    before ->
      @file = @folder.getFile(_.keys(@folder.files)[0])

    context 'buffer updated', ->

      beforeEach (done) ->
        @buffer = "Some buffer from the text editor"
        @folder.bufferUpdate(@file.path, @buffer, done)

      it "should update the corresponding template's buffer", ->
        @file.hasBuffer().should.be.true
        @file.buffer.should.equal(@buffer)

      it "should sync the dirty template to the scratch", (done) ->
        assertFileHasBody(@file.scratchPath, @buffer, done)

      it "should publish an update event", ->
        @emitStub.calledOnce.should.be.true

    context 'cleared', ->
      beforeEach (done) ->
        @buffer = "Some buffer from the text editor"
        @folder.bufferUpdate @file.path, @buffer, =>
          @folder.bufferClear(@file.path, done)

      it "should clear the corresponding template's buffer", ->
        @file.hasBuffer().should.be.false

      it "should sync the dirty templates to the scratch", ->
        assertFilesSame(@file.scratchPath, @file.path)

      it "should publish an update event", ->
        @emitStub.calledOnce.should.be.true

  context 'watching', ->

    context 'file deleted', ->
      beforeEach ->
        @file = @folder.getFile(_.keys(@folder.files)[0])
        @folder._handleFSEvent('deleted', @file.path)

      it "should be removed from the internal representation", ->
        (typeof @folder.getFile(@file.path) == 'undefined').should.be.true

      it "should be removed from the scratch", (done) ->
        assertFileExistance false, @file.scratchPath, done

      it "should publish an update event"

    context 'file created', ->
      before ->
        sourceFile = fixturePath('filesystem/project/styles/style.scss')
        @filePath  = path.join(@folder.path, 'new_file.scss')
        shell.cp sourceFile, @filePath
        @folder._handleFSEvent('created', @filePath)

      it "should add it to its internal representation", ->
        file = @folder.getFile(@filePath)
        file.should.be.ok
        file.path.should.equal @filePath
        file.scratchPath.should.equal @filePath.replace(@folder.path, @folder.scratchPath)

      it "should be added to the scratch", (done) ->
        file = @folder.getFile(@filePath)
        assertFileExistance true, file.scratchPath, ->
          assertFilesSame file.path, file.scratchPath, done

      it "should publish an update event"

    context 'file modified', ->
      before (done) ->
        @changes = "body{background-color: blue;}"
        @file    = @folder.getFile(_.keys(@folder.files)[0])
        fs.writeFile @file.path, @changes, {flags: 'w'}, =>
          @folder._handleFSEvent('modified', @file.path)
          done()

      it "should sync to the scratch", (done) ->
        assertFileHasBody(@file.scratchPath, @changes, done)

      it "should publish an update event"

    context 'folder deleted', ->
      before ->
        @folderPath = path.join(@folder.path, 'styles/bourbon')
        @children   = _.values(@folder.files).filter( (f) => f.path.indexOf(@folderPath) == 0 )
        
        @folder._handleFSEvent('deleted', @folderPath, type: 'directory')

      it 'should remove all children from the internal representation', ->
        @children.forEach (child) =>
          (typeof(@folder.getFile(child.path)) == 'undefined').should.be.true

      it 'should remove all children from the scratch', (done) ->
        Q.allSettled( @children.map (child) => Q.nfcall(assertFileExistance, false, child.scratchPath) )
          .then ->
            done()
          .fail (e) ->
            throw e
          .done()

    context 'project folder deleted', ->
      before ->
        @stopSub = sinon.stub(@folder, 'stop')
        @folder._handleFSEvent('deleted', @folder.path)

      it 'should stop watching', ->
        @stopSub.calledOnce.should.be.true

      it 'should emit a deleted event'

      it 'should publish an update event'




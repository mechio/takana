Folder  = require '../../lib/filesystem/folder'
shell   = require 'shelljs'
path    = require 'path'
sinon   = require 'sinon'
glob    = require 'glob'
_       = require 'underscore'
fs      = require 'fs'

mockFolder = ->
  source  = createEmptyTmpDir('source')
  scratch = path.join(createEmptyTmpDir(), 'scratch')

  shell.cp('-r', fixturePath('filesystem/project'), source)

  new Folder(
    name:        'test_folder'
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
    context 'buffer updated', ->
      it "should update the corresponding template's buffer"
      it "should sync the dirty templates to the scratch"
      it "should publish an update event"

    context 'cleared', ->
      it "should clear the corresponding template's buffer"
      it "should sync the dirty templates to the scratch"   
      it "should publish an update event"

  context 'watching', ->
    context 'file deleted', ->
      before ->
        @file = @folder.getFile(_.keys(@folder.files)[0])
        @folder._handleFSEvent('deleted', @file.path)

      it "should be removed from the internal representation", ->
        (typeof @folder.getFile(@file.path) == 'undefined').should.be.true

      it "should be removed from the scratch", (done) ->
        assertFileExistance false, @file.scratchPath, done

      it "should publish an update event"#, (done) ->
        # @folder.on 'updated', ->
        #   console.log "DDD"


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
      it 'should remove', ->
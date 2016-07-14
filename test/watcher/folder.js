import Folder from '../../lib/watcher/folder';
import shell from 'shelljs';
import path from 'path';
import sinon from 'sinon';
import glob from 'glob';
import _ from 'underscore';
import fs from 'fs';
import Q from 'q';

let mockFolder = function() {
  let source  = createEmptyTmpDir('source');
  let scratch = path.join(createEmptyTmpDir(), 'scratch');

  shell.cp('-r', fixturePath('filesystem/project/*'), source);

  return new Folder({
    extensions:  ['scss', 'css'],
    path:        source,
    scratchPath: scratch
  }
  );
};

describe('Folder', function() {
  before(function(done) {
    this.folder       = mockFolder();
    this.startWatching = sinon.stub(this.folder, 'startWatching');
    assertFileExistance(false, this.folder.scratchPath);
    return this.folder.start(() => done());
  });

  after(function(){
    this.startWatching.restore();
  });

  beforeEach(function() {
    return this.emitStub = sinon.stub(this.folder, 'emitUpdateMessage');
  });
    
  afterEach(function() {
    return this.emitStub.restore();
  });
    // @throttledEmitUpadteStub.restore()    

  context('on start', function() {
    it('should create its scratch folder', function() {
      return assertIsFolder(true, this.folder.scratchPath);
    });

    it('should sync its watched directory to the scratch space', function() {
      return assertFoldersEqual('**/*.{scss,css}', this.folder.path, this.folder.scratchPath);
    });

    it('should have an accurate internal representation of the folder', function(done) {
      this.folder.files.should.not.be.empty;
      return glob(path.join(this.folder.path, "**/*.{scss,css}"), (e, files) => {
        files.length.should.equal(_.keys(this.folder.files).length);
        files.forEach(f => {
          return this.folder.getFile(f).path.should.equal(f);
        });

        return done();
      });
    });

    return it('should start watching its folder for changes', function() {
      return this.startWatching.calledOnce.should.be.true;
    });
  });

  context('template', function() {
    before(function() {
      return this.file = this.folder.getFile(_.keys(this.folder.files)[0]);
    });

    context('buffer updated', function() {

      beforeEach(function(done) {
        this.buffer = "Some buffer from the text editor";
        return this.folder.bufferUpdate({path: this.file.path, buffer: this.buffer}, done);
      });

      it("should update the corresponding template's buffer", function() {
        this.file.hasBuffer().should.be.true;
        return this.file.buffer.should.equal(this.buffer);
      });

      it("should sync the dirty template to the scratch", function(done) {
        return assertFileHasBody(this.file.scratchPath, this.buffer, done);
      });

      return it("should publish an update event", function() {
        return this.emitStub.calledOnce.should.be.true;
      });
    });

    return context('cleared', function() {
      beforeEach(function(done) {
        this.buffer = "Some buffer from the text editor";
        return this.folder.bufferUpdate({path: this.file.path, buffer: this.buffer}, () => {
          return this.folder.bufferClear(this.file.path, done);
        });
      });

      it("should clear the corresponding template's buffer", function() {
        return this.file.hasBuffer().should.be.false;
      });

      it("should sync the dirty templates to the scratch", function() {
        return assertFilesSame(this.file.scratchPath, this.file.path);
      });

      return it("should publish an update event", function() {
        return this.emitStub.calledOnce.should.be.true;
      });
    });
  });

  return context('watching', function() {

    context('file deleted', function() {
      beforeEach(function() {
        this.file = this.folder.getFile(_.keys(this.folder.files)[0]);
        return this.folder._handleFSEvent('deleted', this.file.path);
      });

      it("should be removed from the internal representation", function() {
        return (typeof this.folder.getFile(this.file.path) === 'undefined').should.be.true;
      });

      it("should be removed from the scratch", function(done) {
        return assertFileExistance(false, this.file.scratchPath, done);
      });

      return it("should publish an update event");
    });

    context('file created', function() {
      before(function() {
        let sourceFile = fixturePath('filesystem/project/styles/style.scss');
        this.filePath  = path.join(this.folder.path, 'new_file.scss');
        shell.cp(sourceFile, this.filePath);
        return this.folder._handleFSEvent('created', this.filePath);
      });

      it("should add it to its internal representation", function() {
        let file = this.folder.getFile(this.filePath);
        file.should.be.ok;
        file.path.should.equal(this.filePath);
        return file.scratchPath.should.equal(this.filePath.replace(this.folder.path, this.folder.scratchPath));
      });

      it("should be added to the scratch", function(done) {
        let file = this.folder.getFile(this.filePath);
        return assertFileExistance(true, file.scratchPath, () => assertFilesSame(file.path, file.scratchPath, done));
      });

      return it("should publish an update event");
    });

    context('file modified', function() {
      before(function(done) {
        this.changes = "body{background-color: blue;}";
        this.file    = this.folder.getFile(_.keys(this.folder.files)[0]);
        return fs.writeFile(this.file.path, this.changes, {flags: 'w'}, () => {
          this.folder._handleFSEvent('modified', this.file.path);
          return done();
        });
      });

      it("should sync to the scratch", function(done) {
        return assertFileHasBody(this.file.scratchPath, this.changes, done);
      });

      return it("should publish an update event");
    });

    context('folder deleted', function() {
      before(function() {
        this.folderPath = path.join(this.folder.path, 'styles/bourbon');
        this.children   = _.values(this.folder.files).filter( f => f.path.indexOf(this.folderPath) === 0 );
        
        return this.folder._handleFSEvent('deleted', this.folderPath, {type: 'directory'});
      });

      it('should remove all children from the internal representation', function() {
        return this.children.forEach(child => {
          return (typeof(this.folder.getFile(child.path)) === 'undefined').should.be.true;
        });
      });

      return it('should remove all children from the scratch', function(done) {
        return Q.allSettled( this.children.map(child => Q.nfcall(assertFileExistance, false, child.scratchPath)) )
          .then(() => done())
          .fail(function(e) {
            throw e;
          })
          .done();
      });
    });

    return context('project folder deleted', function() {
      before(function() {
        this.stopSub = sinon.stub(this.folder, 'stop');
        return this.folder._handleFSEvent('deleted', this.folder.path);
      });

      it('should stop watching', function() {
        return this.stopSub.calledOnce.should.be.true;
      });

      it('should emit a deleted event');

      return it('should publish an update event');
    });
  });
});




import Server from '../lib/server'; 
import path from 'path';
import sinon from 'sinon';
import _ from 'underscore';

let scratchPath = path.join(createEmptyTmpDir(), 'scratchy');

describe('Server', function() {
  beforeEach(function() {
    this.server = new Server({
      name:         'default',
      path:         fixturePath('foundation5'),
      scratchPath,
      includePaths: []
    });
  });

  describe('start', function() {
    beforeEach(function(done) {
      this.startSpies = [
        sinon.spy(this.server.webServer, 'listen'),
        sinon.spy(this.server.editorManager, 'start'),
        sinon.spy(this.server.browserManager, 'start'),
        sinon.spy(this.server.folder, 'start')
      ];
      this.server.start(done);
    });

    afterEach(function(done) {
      this.server.stop(done);
      this.startSpies.forEach(spy => { return spy.restore() });
    });

    it('should create the scratchPath folder', function() {
      assertIsFolder(true, this.server.options.scratchPath);
    });

    it('should start its subservices', function() {
      this.startSpies.forEach(spy => { return spy.calledOnce.should.be.true });
    });
  });
  
  context('when the server is running', function() {

    beforeEach(function(done) {
      this.server.start(done);
    });

    afterEach(function(done) {
      return this.server.stop(done);
    });

    context('received folder updated event', function() {

      
      it('should call handleFolderUpdate', function() {
        console.log('here');
    
        let stub = sinon.stub(this.server, 'handleFolderUpdate');
        this.server.folder.emit('updated');
        stub.called.should.be.true;
        return stub.restore();
      })
    });

    context('received buffer:update event', () =>
      it('should call bufferUpdate on the folder', function() {
        let stub = sinon.stub(this.server.folder, 'bufferUpdate');
        let data = {path: this.server.options.path + '/some/file.scss'};

        this.server.editorManager.emit('buffer:update', data);
        stub.calledWith(data).should.be.true;
        return stub.restore();
      })
    );
        
    context('received buffer:reset event', () =>
      it('should call bufferClear on the folder', function() {
        let stub = sinon.stub(this.server.folder, 'bufferClear');
        let data = {path: this.server.options.path + '/some/file.scss'};

        this.server.editorManager.emit('buffer:reset', data);
        stub.calledWith(data.path).should.be.true;
        return stub.restore();
      })
    );
        
    context('received stylesheet:resolve event', function() {
      context('matching stylesheet', () =>
        it('should callback with the path of the matched stylesheet', function(done) {
          return this.server.browserManager.emit('stylesheet:resolve', {href: '/css/app.css'}, (error, match) => done());
        })
      );

      context('no matching stylesheet', () => it('should callback with an error'));
    });

    describe('handleFolderUpdate', function() {
      it('should render all watched stylesheets on the project');
      it('should work with include paths');
      context('successful render', () => it('should notify the browser manager'));
    });
  });
});


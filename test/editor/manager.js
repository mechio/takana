import editor from '../../lib/editor';
import sinon from 'sinon';
import nssocket from 'nssocket';

describe('editor.Manager', function() {
  before(function(done) {
    this.editorManager = new editor.Manager({port: 5000});
    return this.editorManager.start(done);
  });

  after(function() {
    return this.editorManager.stop();
  });
    

  it('should emit buffer:update when the editor updates its buffer', function(done) {
    let outbound = new nssocket.NsSocket();
    let payload  = {path: '/path/to/some/file'};

    this.editorManager.once('buffer:reset', function(data) {
      data.should.eql(payload);
      return done();
    });

    outbound.on('start', () => outbound.send(['editor', 'reset'], payload));
        
    return outbound.connect(this.editorManager.port);
  });

  return it('should emit buffer:clear when the editor clears its buffer', function(done) {
    let outbound = new nssocket.NsSocket();
    let payload  = { 
      path: '/path/to/some/file',
      created_at: 123456,
      buffer: 'hello jag jag'
    };

    this.editorManager.once('buffer:update', function(data) {
      data.path.should.eql(payload.path);
      data.timestamp.should.eql(payload.created_at);
      data.buffer.should.eql(payload.buffer);
      return done();
    });

    outbound.on('start', () => outbound.send(['editor', 'update'], payload));
        
    return outbound.connect(this.editorManager.port);
  });
});

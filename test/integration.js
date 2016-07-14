import Server from '../lib/server'; 
import path from 'path';

describe('Server', function() {
  beforeEach(function() {
    return this.server = new Server({
      name:         'default',
      path:         fixturePath('foundation5'),
      scratchPath:  createEmptyTmpDir(),
      includePaths: []
    });
  });


  it('should work for a css project', function() {});

  return it('should work for a foundation project', function() {});
});

    




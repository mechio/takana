import css from '../../lib/renderer/css';

describe('css', () =>
  describe('render', function() {
    it('should return the body', function(done) {
      let file = fixturePath('css/style.css');
      return css.render({file}, function(error, data) {
        (error === null).should.be.true;
        return assertFileHasBody(file, data.body, done);
      });
    });
        
    return context('writeToDisk = true', () =>
      it('should return the path to the css file on disk', function(done) {
        let file = fixturePath('css/style.css');
        return css.render({file, writeToDisk: true}, function(error, data) {
          data.cssFile.should.equal(file);
          return done();
        });
      })
    );
  })
);


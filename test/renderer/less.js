import less from '../../lib/renderer/less';
import path from 'path';
import shell from 'shelljs';


describe('less', () =>
  describe('render', function() {
    it('should return an error when the render is unsuccessful', function(done) {
      let file = fixturePath('less/error/style.less');
      return less.render({file}, function(error, body) {
        error.file.should.equal(file);
        error.line.should.be.ok;
        error.message.should.be.ok;
        (body === null).should.be.true;
        return done();
      });
    });

    context('writeToDisk = true', function() {
      beforeEach(() => {
        this.options = {
          file: fixturePath('less/kube/kube.less'),
          writeToDisk: true
        };
      });

      afterEach(done =>
        setTimeout(() => {
          shell.rm('-f', this.options.file + '.css');
          shell.rm('-f', this.options.file + '.css.map');
          return done();
        }
        , 10)
      );

      return it('should write the css and source map to disk', (done) => {
        return less.render(this.options, (error, result) => {
          assertFileHasBody(this.options.file + '.css', result.body);
          assertFileHasBody(this.options.file + '.css.map', result.sourceMap);
          result.cssFile.should.equal(this.options.file + '.css');
          return done();
        });
      });
    });

    it('should return css with a valid source map', () => {
      let file     = fixturePath('less/kube/style.less');
      return less.render({file}, function(error, result) {
        result.body.toString().should.containEql('sourceMappingURL=style.less.css.map');
        return JSON.parse(result.sourceMap.toString()).sources[0].should.equal('style.less');
      });
    });
  
    it('should work with includePaths');
  })
);
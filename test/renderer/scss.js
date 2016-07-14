import scss from '../../lib/renderer/scss';
import sass from 'node-sass';
import path from 'path';
import shell from 'shelljs';

let sassRender = function(options, callback) {
  let outFile       = options.file + '.css';
  let sourceMap     = options.file + '.css.map';

  let renderOptions = { 
    file           : options.file,
    includePaths   : options.includePaths,
    outFile,
    sourceComments : 'map',
    sourceMap
  };

  sass.render(renderOptions, (error, result) => {
    if(error) {
        if (callback) {
          callback(error, null);
        }
    } else {
        let { css } = result;
        sourceMap = result.map;
        if (callback) {
          callback(null, {
            body:      css,
            sourceMap
          });
        }
      }
    }
  );
};


describe('scss', () =>
  describe('render', function() {
    it('should return an error when the render is unsuccessful', function(done) {
      let file = fixturePath('scss/error/style.scss');
      scss.render({file}, function(error, body) {
        error.file.should.equal(file);
        error.line.should.be.ok;
        error.message.should.be.ok;
        (body === null).should.be.true;
        done();
      });
    });

    context('writeToDisk = true', function() {
      beforeEach(() => {
        this.options = {
          file: fixturePath('scss/foundation/style.scss'),
          writeToDisk: true
        };
      });

      afterEach(done =>
        setTimeout(() => {
          shell.rm('-f', this.options.file + '.css');
          shell.rm('-f', this.options.file + '.css.map');
          done();
        }
        , 10)
      );

      it('should write the css and source map to disk', (done) => {
        scss.render(this.options, (error, result) => {
          assertFileHasBody(this.options.file + '.css', result.body);
          assertFileHasBody(this.options.file + '.css.map', result.sourceMap);
          result.cssFile.should.equal(this.options.file + '.css');
          done();
        });
      });
    });

    it('should return css with a valid source map', () => {
      let file     = fixturePath('scss/foundation/style.scss');
      scss.render({file}, function(error, result) {
        result.body.toString().should.containEql('sourceMappingURL=style.scss.css.map');
        JSON.parse(result.sourceMap.toString()).sources[0].should.equal('style.scss');
      });
    });

    it('should have the same output as the sass compiler', (done) => {
      let file     = fixturePath('scss/foundation/style.scss');
      sassRender({file}, (error, sassResult) =>
        scss.render({file}, function(error, takanaResult) {
          takanaResult.body.toString().should.be.eql(sassResult.body.toString());
          takanaResult.sourceMap.toString().should.be.eql(sassResult.sourceMap.toString());
          done();
        })
      );
    });
      
    it('should work with includePaths', (done) => {
      let options = { 
        file         : fixturePath('scss/include-paths/style.scss'),
        includePaths : [fixturePath('scss')]
      };
      
      sassRender(options, (error, sassResult) =>
        scss.render(options, function(error, takanaResult) {
          takanaResult.body.toString().should.be.eql(sassResult.body.toString());
          takanaResult.sourceMap.toString().should.be.eql(sassResult.sourceMap.toString());
          done();
        })
      );
    });
  })
);

import renderer from '../../lib/renderer';

describe('renderer', function() {
  describe('for', () =>
    it('should return a renderer for a supported file', function() {
      renderer.for('/path/to/blah.scss').should.equal(renderer.renderers.scss);
      renderer.for('/path/to/blah.sass').should.equal(renderer.renderers.scss);      
      renderer.for('/path/to/blah.css').should.equal(renderer.renderers.css);
      (renderer.for('/path/to/blah.sdsd') === undefined).should.equal(true);
    })
  );
  return describe('supportedExtensions', function() {
    it('should support css', () => renderer.supportedExtensions().should.containEql('css'));
    it('should support scss', () => renderer.supportedExtensions().should.containEql('scss'));
    it('should support sass', () => renderer.supportedExtensions().should.containEql('sass'));
    it('should support less', () => renderer.supportedExtensions().should.containEql('less'));
  });
});      
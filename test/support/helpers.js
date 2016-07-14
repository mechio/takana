import helpers from '../../lib/support/helpers';

describe('helpers', function() {
  describe('sanitizePath', function() {
    it('should expand the tilde path', function() {
      helpers.sanitizePath('~').should.equal(process.env.HOME + '/');
      return helpers.sanitizePath('~/.takana/projects/').should.equal(process.env.HOME + '/.takana/projects/');
    });

    return it('should add a trailing slash', () => helpers.sanitizePath('/path/to/something').should.equal('/path/to/something/'));
  });

  describe('extname', () =>
    it('should return the extension of a file', function() {
      helpers.extname('/path/to/some/file.css').should.equal('css');
      return helpers.extname('/path/to/some/file.scss').should.equal('scss');
    })
  );

  describe('isFileOfType', function() {
    it('should return true if the file is one of the types', () => helpers.isFileOfType('/path/to/blah.scss', ['scss']).should.be.true);

    return it('should return false if the file is not one of the types', () => helpers.isFileOfType('/path/to/blah.scss', ['css']).should.be.false);
  });

  return describe('fastFind', function() {
    it('should have the same output as glob');
    return it('should work with huge directories (>2000 files)');
  });
});

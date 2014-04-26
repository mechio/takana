helpers = require '../../lib/support/helpers'

describe 'helpers', ->
  describe 'sanitizePath', ->
    it 'should expand the tilde path', ->
      helpers.sanitizePath('~').should.equal(process.env.HOME + '/')
      helpers.sanitizePath('~/.takana/projects/').should.equal(process.env.HOME + '/.takana/projects/')

    it 'should add a trailing slash', ->
      helpers.sanitizePath('/path/to/something').should.equal('/path/to/something/')

  describe 'extname', ->
    it 'should return the extension of a file', ->
      helpers.extname('/path/to/some/file.css').should.equal('css')
      helpers.extname('/path/to/some/file.scss').should.equal('scss')

  describe 'isFileOfType', ->
    it 'should return true if the file is one of the types', ->
      helpers.isFileOfType('/path/to/blah.scss', ['scss']).should.be.true

    it 'should return false if the file is not one of the types', ->
      helpers.isFileOfType('/path/to/blah.scss', ['css']).should.be.false

  describe 'fastFind', ->
    it 'should have the same output as glob'


  describe 'absolutizeUrls', ->
    it "should absolutize all urls in a template", ->
      style = """
        .el1 {
          background-image: url(path/to/some/image.png);
        }

        .el2 {
          background-image: url('/path/to/some/image.png');
        }

        .el3 {
          background-image: url(//cake.com/some/crazy/image.png);
        }

        .el4 {
          background-image: url(http://pooter.com/some/crazy/image.png);
        }
      """
      href = "https://jahrasta.com/jah/is/the/most/high/style.css"

      expected = """
        .el1 {
          background-image: url('https://jahrasta.com/jah/is/the/most/high/path/to/some/image.png');
        }

        .el2 {
          background-image: url('https://jahrasta.com/path/to/some/image.png');
        }

        .el3 {
          background-image: url('https://cake.com/some/crazy/image.png');
        }

        .el4 {
          background-image: url('http://pooter.com/some/crazy/image.png');
        }
      """

      helpers.absolutizeUrls(style, href).should.equal(expected)

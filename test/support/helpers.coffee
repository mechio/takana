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
    it 'should work with huge directories (>2000 files)'

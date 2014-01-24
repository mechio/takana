helpers = require '../lib/helpers'

describe 'helpers', ->
  describe 'expandPath', ->
    it 'should expand the tilde path', ->
      helpers.expandPath('~').should.equal(process.env.HOME)
      helpers.expandPath('~/.takana/projects').should.equal(process.env.HOME + '/.takana/projects')
      helpers.expandPath('/path/to/something').should.equal('/path/to/something')

  describe 'extname', ->
    it 'should return the extension of a file', ->
      helpers.extname('/path/to/some/file.css').should.equal('css')
      helpers.extname('/path/to/some/file.scss').should.equal('scss')
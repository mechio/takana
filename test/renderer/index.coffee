renderer = require '../../lib/renderer'

describe 'renderer', ->
  describe 'for', ->
    it 'should return a renderer for a supported file', ->
      renderer.for('/path/to/blah.scss').should.equal(renderer.scss)
      renderer.for('/path/to/blah.css').should.equal(renderer.css)
      (renderer.for('/path/to/blah.sdsd') == undefined).should.be.true
  describe 'supportedExtensions', ->
    it 'should support css', ->
      renderer.supportedExtensions().should.containEql('css')
    it 'should support scss', ->
      renderer.supportedExtensions().should.containEql('scss')
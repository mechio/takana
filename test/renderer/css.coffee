css = require '../../lib/renderer/css'

describe 'css', ->
  describe 'render', ->
    it 'should return the body', (done) ->
      css.render file: fixturePath('css/style.css'), (error, body) ->
        body.should.be.type('string')
        (error == null).should.be.true
        done()


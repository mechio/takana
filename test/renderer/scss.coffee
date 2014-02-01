scss = require '../../lib/renderer/scss'

describe 'scss', ->
  describe 'render', ->
    it 'should return the body when the render is successful', (done) ->
      file = fixturePath('scss/foundation/style.scss')
      scss.render file: file, (error, body) ->
        body.should.be.type('string')
        (error == null).should.be.true
        done()

    it 'should return an error when the render is unsuccessful', (done) ->
      file = fixturePath('scss/error/style.scss')
      scss.render file: file, (error, body) ->
        error.file.should.equal(file)
        error.line.should.be.ok
        error.message.should.be.ok
        (body == null).should.be.true
        done()

    it 'should have the same output as the sass compiler'
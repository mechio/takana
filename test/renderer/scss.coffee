scss = require '../../lib/renderer/scss'
sass = require 'node-sass'

describe 'scss', ->
  describe 'render', ->
    it 'should return an error when the render is unsuccessful', (done) ->
      file = fixturePath('scss/error/style.scss')
      scss.render file: file, (error, body) ->
        error.file.should.equal(file)
        error.line.should.be.ok
        error.message.should.be.ok
        (body == null).should.be.true
        done()

    it 'should have the same output as the sass compiler', (done) ->
      file = fixturePath('scss/foundation/style.scss')

      scss.render file: file, (error, body) ->
        body.should.be.type('string')
        (error == null).should.be.true
        sass.render(
          file    : file
          success : (sassBody) =>
            sassBody.should.equal(body)
            done()
        )

    it 'should work with includePaths', (done) ->
      file = fixturePath('scss/include-paths/style.scss')
      
      options = { 
        file: file,
        includePaths: [fixturePath('scss')]
      }

      scss.render options, (error, body) ->
        body.should.be.type('string')
        (error == null).should.be.true
        
        options["success"] = (sassBody) =>
          sassBody.should.equal(body)
          done()
        sass.render(options)

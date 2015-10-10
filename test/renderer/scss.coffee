scss  = require '../../lib/renderer/scss'
sass  = require 'node-sass'
path  = require 'path'
shell = require 'shelljs'
sassRender = (options, callback) ->
  outFile       = options.file + '.css'
  sourceMap     = options.file + '.css.map'

  renderOptions = 
    file           : options.file
    includePaths   : options.includePaths
    outFile        : outFile
    sourceComments : 'map'
    sourceMap      : sourceMap

  sass.render(renderOptions, (error, result) =>
      if(error)
          callback?(error, null)
      else
          css = result.css
          sourceMap = result.map
          callback?(null, {
            body:      css
            sourceMap: sourceMap
          })
  )


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

    context 'writeToDisk = true', ->
      beforeEach ->
        @options =
          file: fixturePath('scss/foundation/style.scss')
          writeToDisk: true

      afterEach (done) ->
        setTimeout =>
          shell.rm('-f', @options.file + '.css')
          shell.rm('-f', @options.file + '.css.map')
          done()
        , 10

      it 'should write the css and source map to disk', (done) ->
        scss.render @options, (error, result) =>
          assertFileHasBody(@options.file + '.css', result.body)
          assertFileHasBody(@options.file + '.css.map', result.sourceMap)
          result.cssFile.should.equal(@options.file + '.css')
          done()

    it 'should return css with a valid source map', ->
      file     = fixturePath('scss/foundation/style.scss')
      scss.render file: file, (error, result) ->
        result.body.toString().should.containEql('sourceMappingURL=style.scss.css.map');
        JSON.parse(result.sourceMap.toString()).sources[0].should.equal('style.scss')

    it 'should have the same output as the sass compiler', (done) ->
      file     = fixturePath('scss/foundation/style.scss')
      sassRender file: file, (error, sassResult) ->
        scss.render file: file, (error, takanaResult) ->
          takanaResult.body.toString().should.be.eql(sassResult.body.toString())
          takanaResult.sourceMap.toString().should.be.eql(sassResult.sourceMap.toString())
          done()
      
    it 'should work with includePaths', (done) ->
      options = 
        file         : fixturePath('scss/include-paths/style.scss')
        includePaths : [fixturePath('scss')]
      
      sassRender options, (error, sassResult) ->
        scss.render options, (error, takanaResult) ->
          takanaResult.body.toString().should.be.eql(sassResult.body.toString())
          takanaResult.sourceMap.toString().should.be.eql(sassResult.sourceMap.toString())
          done()

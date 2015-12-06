less  = require '../../lib/renderer/less'
path  = require 'path'
shell = require 'shelljs'


describe 'less', ->
  describe 'render', ->
    it 'should return an error when the render is unsuccessful', (done) ->
      file = fixturePath('less/error/style.less')
      less.render file: file, (error, body) ->
        error.file.should.equal(file)
        error.line.should.be.ok
        error.message.should.be.ok
        (body == null).should.be.true
        done()

    context 'writeToDisk = true', ->
      beforeEach ->
        @options =
          file: fixturePath('less/kube/kube.less')
          writeToDisk: true

      afterEach (done) ->
        setTimeout =>
          shell.rm('-f', @options.file + '.css')
          shell.rm('-f', @options.file + '.css.map')
          done()
        , 10

      it 'should write the css and source map to disk', (done) ->
        less.render @options, (error, result) =>
          assertFileHasBody(@options.file + '.css', result.body)
          assertFileHasBody(@options.file + '.css.map', result.sourceMap)
          result.cssFile.should.equal(@options.file + '.css')
          done()

    it 'should return css with a valid source map', ->
      file     = fixturePath('less/kube/style.less')
      less.render file: file, (error, result) ->
        result.body.toString().should.containEql('sourceMappingURL=style.less.css.map');
        JSON.parse(result.sourceMap.toString()).sources[0].should.equal('style.less')
  
    it 'should work with includePaths'
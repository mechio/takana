middleware = require '../../lib/support/middleware'
express    = require 'express'
http       = require 'http'
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

describe 'middleware', ->

  describe 'absolutizeUrls', ->
    it "should absolutize urls in a template", ->
      middleware.absolutizeUrls(style, href).should.equal(expected)

  describe 'absolutizeCSSUrls', ->
    beforeEach (done) ->
      app         = express()
      @webServer  = http.createServer(app)

      @port = 3000

      app.use middleware.absolutizeCSSUrls
      app.use '/live', express.static(fixturePath('css'))

      @webServer.listen @port, =>
        done()

    afterEach (done) ->
      @webServer.close -> done()
        
    it "should pass through a css file", (done) ->
      request = http.get "http://localhost:#{@port}/live/style.css", (res) ->
        body = ''

        res.on 'data', (chunk) -> 
          body += chunk

        res.on 'end', (chunk) -> 
          body.should.equal("""
            body {
              background-color: red;
            }
          """)
          done()

      request.on 'error', (e) ->
        console.log("Got error: " + e.message)
        done()


middleware = require '../../lib/support/middleware'

describe 'middleware', ->

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

      middleware.absolutizeUrls(style, href).should.equal(expected)

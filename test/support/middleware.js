import middleware from '../../lib/support/middleware';
import express from 'express';
import http from 'http';
let style = `.el1 {
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
}`;
let href = "https://jahrasta.com/jah/is/the/most/high/style.css";

let expected = `.el1 {
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
}`;

describe('middleware', function() {

  describe('absolutizeUrls', () =>
    it("should absolutize urls in a template", () => middleware.absolutizeUrls(style, href).should.equal(expected))
  );

  return describe('absolutizeCSSUrls', function() {
    beforeEach(function(done) {
      let app         = express();
      this.webServer  = http.createServer(app);

      this.port = 3000;

      app.use(middleware.absolutizeCSSUrls);
      app.use('/live', express.static(fixturePath('css')));

      return this.webServer.listen(this.port, () => {
        return done();
      });
    });

    afterEach(function(done) {
      return this.webServer.close(() => done());
    });
        
    return it("should pass through a css file", function(done) {
      let request = http.get(`http://localhost:${this.port}/live/style.css`, function(res) {
        let body = '';

        res.on('data', chunk => body += chunk);

        return res.on('end', function(chunk) { 
          body.should.equal(`body {
  background-color: red;
}`);
          return done();
        });
      });

      return request.on('error', function(e) {
        console.log(`Got error: ${e.message}`);
        return done();
      });
    });
  });
});


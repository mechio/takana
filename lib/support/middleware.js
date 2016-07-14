import url from 'url';
import mime from 'mime';

let absolutizeUrls = function(body, href) {
  let urlRegex = /url\([\"|\']{0,1}([^\)|^\"|^\']+)[\"|\']{0,1}\)/g;
  let joinUrl  = url.resolve;
  let { protocol } = url.parse(href);
  body = body.replace(urlRegex, function(m, url) {
    if (/^\/\/.*/.test(url)) { url = protocol + url; }
    url = joinUrl(href, url);
    return `url('${url}')`;
  });
  return body;
};

let absolutizeCSSUrls = function(req, res, next) {
  let { write } = res;
  let { end }   = res;

  let data            = new Buffer(0);
  let transform       = true;
  let bodyIsHtml      = false;

  res.write = function(chunk, encoding) {
    // data += chunk.toString()
    if (!this.headerSent) { this._implicitHeader(); }
    if (bodyIsHtml) {
      return data = Buffer.concat([data, new Buffer(chunk, encoding)]);
    } else {
      return write.call(res, chunk, encoding);
    }
  };

  res.end = function(chunk, encoding) {  
    if (bodyIsHtml) {
      if (chunk) { this.write(chunk, encoding); }

      let { href } = req.query;

      if (href) {
        write.call(res, absolutizeUrls(data.toString(), href));
      } else {
        write.call(res, data.toString());
      }

      return end.call(res);

    } else {
      return end.call(res, chunk, encoding);
    }
  };

  res.on('header', function() {
    let contentType = res.getHeader('Content-Type'); 
    if (contentType && mime.extension( contentType ) === 'css') {
      // We know that it's css
      res.removeHeader('Content-Length');      
      return bodyIsHtml = true;
    }
  });

  return next();
};
module.exports = { absolutizeUrls: absolutizeUrls, absolutizeCSSUrls: absolutizeCSSUrls };
url  = require 'url'
mime = require('mime')

exports.absolutizeUrls = absolutizeUrls = (body, href) ->
  urlRegex = ///
    url\(
      [\"|\']{0,1}
      ([^\)|^\"|^\']+)
      [\"|\']{0,1}
    \)                  #
  ///g
  joinUrl  = url.resolve
  protocol = url.parse(href).protocol
  body = body.replace urlRegex, (m, url) ->
    url = protocol + url if /^\/\/.*/.test(url)
    url = joinUrl(href, url)
    "url('#{url}')"
  body

exports.absolutizeCSSUrls = absolutizeCSSUrls = (req, res, next) ->
  write = res.write
  end   = res.end

  data            = new Buffer(0)
  transform       = true
  bodyIsHtml      = false

  res.write = (chunk, encoding) ->
    # data += chunk.toString()
    @_implicitHeader() if !@headerSent
    if bodyIsHtml
      data = Buffer.concat [data, new Buffer(chunk, encoding)]
    else
      write.call(res, chunk, encoding)

  res.end = (chunk, encoding) ->  
    if bodyIsHtml
      @write(chunk, encoding) if chunk

      href = req.query.href

      if href
        write.call(res, absolutizeUrls(data.toString(), href))
      else
        write.call(res, data.toString())

      end.call(res)

    else
      end.call(res, chunk, encoding)

  res.on 'header', ->
    contentType = res.getHeader('Content-Type') 
    if contentType && mime.extension( contentType ) == 'css'
      # We know that it's css
      res.removeHeader('Content-Length')      
      bodyIsHtml = true

  next()
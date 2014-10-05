url         = require 'url'

absolutizeUrls = (body, href) ->
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

exports.absolutizeCSSUrls = absolutizeCSSUrls = (mutator) ->
  (req, res, next) ->
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

        # This is where we start fiddling with the data

        document = domstream(data)
        document.on 'data', (data) ->
          write.call(res, data)

        document.on 'end', (data) ->
          end.call(res, data)

        mutator(req, document)
      else
        end.call(res, chunk, encoding)

    res.on 'header', ->
      contentType = res.getHeader('Content-Type') 
      if contentType && mime.extension( contentType ) == 'html'
        # We know that it's html
        res.removeHeader('Content-Length')      
        bodyIsHtml = true

    next()

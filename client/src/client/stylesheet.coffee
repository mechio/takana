class Takana.StyleSheet
  stylesheetReloadTimeout = 15000

  constructor: (attributes) ->
    @documentStyleSheet = attributes.documentStyleSheet
    @el                 = @documentStyleSheet.ownerNode
    @href               = @documentStyleSheet.href
    @id                 = attributes.id

  startListening: ->
    Takana.Server.instance.send 'stylesheet:listen', id: @id
    Takana.Server.instance.bind 'stylesheet:updated', (data) =>
      @update(data.url) if data.id == @id

  #
  # Wait for styles to be applied
  # 
  onceCSSIsLoaded: (clone, callback) ->
    callbackExecuted  = no
    timer             = null

    executeCallback = =>
      return if callbackExecuted
      clearInterval timer
      callbackExecuted = yes
      additionalWaitingTime = if /AppleWebKit/.test(navigator.userAgent) then 5 else 100
      setTimeout(callback, additionalWaitingTime)

    clone.onload = => executeCallback()

    setTimeout executeCallback, stylesheetReloadTimeout


  update: (url) ->
    #
    # Create a new stylesheet linked to Takana Server
    #
    href = "http://#{Takana.Config.hostname}:#{Takana.Config.port}/#{url}?#{Date.now()}&href=#{encodeURIComponent(@href)}"
    el = document.createElement("link")
    el.setAttribute("type", "text/css")
    el.setAttribute("href", href)
    el.setAttribute("media", "all")
    el.setAttribute("rel", "stylesheet")

    # TODO: use stylesheet parent El
    parentTagName = if document.body.contains(@el)
      "body"
    else
      "head"

    document.getElementsByTagName(parentTagName)[0].insertBefore(el, @el)

    @onceCSSIsLoaded el, => 
      @el.remove()
      @el = el

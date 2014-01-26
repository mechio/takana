class Takana.Server
  constructor: (attributes, callback) ->
    @projectName = attributes.projectName
    @url = "ws://#{Takana.Config.hostname}:#{Takana.Config.port}/browser?project_name=#{@projectName}"
    @socket = new WebSocket(@url)
    @socket.onopen = callback

    @socket.onmessage = (event) =>
      message = JSON.parse(event.data)
      @trigger(message.event, message.data)

  send: (event, data)->
    if @socket.readyState == WebSocket.OPEN
      @socket.send JSON.stringify(event: event, data: data)

MicroEvent.mixin(Takana.Server)

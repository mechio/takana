class FakeWebSocket
  @SOCKET = null
  OPEN: 1

  constructor: (@url) ->
    @constructor.SOCKET = @

  # 
  # For tests
  #
  _open: -> 
    @onopen()

  _message: (event) ->
    @onmessage(event)

  readyState: @OPEN

class FakeServer

setupFakeWebSocket = ->
  beforeEach ->
    @websocket = WebSocket
    window.WebSocket = FakeWebSocket

  afterEach ->
    WebSocket = @websocket

setupScriptTag = ->
  injectScriptTag = (options={}) ->
    options.projectName ||= 'testProject'
    options.src         ||= 'http://localhost:48626/takana.js'

    el = document.createElement("script")
    el.setAttribute('data-project', options.projectName)
    el.setAttribute('src', options.src)
    el.setAttribute('id', 'test-script-tag')
    document.body.appendChild(el)

    el

  removeScriptTag = -> 
    @scriptTag.parentNode.removeChild(@scriptTag) if @scriptTag && @scriptTag.parentNode

  beforeEach -> 
    @scriptTag = injectScriptTag()

  afterEach ->
    removeScriptTag()

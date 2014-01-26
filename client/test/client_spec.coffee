describe 'Takana.Client', ->

  describe 'start', ->
    setupScriptTag()

    context 'initialize configuration', ->
      beforeEach ->
        @client = Takana.Client.start()

      it 'should find the Takana script tag', ->
        expect(@client.scriptTag).to.eql(@scriptTag)

      it 'should get the project name from the script tag', ->
        expect(@client.projectName).to.eql('testProject')

      it 'should set the port', ->
        expect(Takana.Config.port).to.eql(48626)

      it 'should set hostname based on scriptTag src', ->
        expect(Takana.Config.hostname).to.eql('localhost')

    context 'WebSocket', ->
      setupFakeWebSocket()

      it 'should connect to the Takana server', ->
        @client = Takana.Client.start()
        expect(Takana.Server.instance.socket.readyState).to.equal(WebSocket.OPEN)

      describe 'once connected', ->
        beforeEach ->
          @client = Takana.Client.start()
          @socket = FakeWebSocket.SOCKET
          @socket.send = sinon.spy()
          @socket._open()

        it 'should send stylesheet:resolve message', ->
          expect(@socket.send.calledOnce).to.equal(true)
          expect(@socket.send.firstCall.args[0]).to.include('stylesheet:resolve')

        it 'should create a project instance', ->
          expect(@client.project.name).to.equal('testProject')

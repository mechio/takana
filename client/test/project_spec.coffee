describe 'Takana.Project', ->
	beforeEach ->
		Takana.Server.instance = new FakeServer
		@bind = Takana.Server.instance.bind = sinon.stub()
		@send = Takana.Server.instance.send = sinon.stub()

	it 'should set the project name on initialize', ->
		@project = new Takana.Project(name: 'foo')
		expect(@project.name).to.eql('foo')

	it 'should find all document stylesheets loaded via http and file protocols', ->
		# create a local stylesheet
		el = document.createElement("style")
		el.setAttribute('type', 'text/css')
		document.body.appendChild(el)

		@project = new Takana.Project(name: 'foobar')
		expect(@project.documentStyleSheets).to.eql([document.styleSheets[0]])		

	it 'should ask the server to resolve all stylesheets', ->
		@project = new Takana.Project(name: 'foobar')

		expect(@project.documentStyleSheets).to.eql([document.styleSheets[0]])		
		expect(@send).to.have.been.calledOnce
		expect(@send).to.have.been.calledWith("stylesheet:resolve")
		expect(@send.firstCall.args[1].href).to.include("http://#{window.location.host}/base/test/css/test.css")

	it 'should instantiate and start listening to a stylesheet once it has been resolved', ->
		@project = new Takana.Project(name: 'foobar')

		# fake 'stylesheet:resolved' callback
		# 
		@bind.firstCall.args[1]
			id: 1
			href: document.styleSheets[0].href
		
		styleSheet = @project.styleSheets["1"]

		expect(styleSheet.documentStyleSheet).to.equal(document.styleSheets[0])
		expect(styleSheet.id).to.equal(1)

		expect(@send).to.have.been.calledWith("stylesheet:listen", id: 1)

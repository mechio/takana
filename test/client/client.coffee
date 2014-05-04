Client = require '../../lib/client'
Server = require '../../lib/server'
path   = require 'path'
shell  = require 'shelljs'

describe 'Client', ->
  before ->
    @client  = new Client()


  context 'server running', ->
    before (done) ->
      testDB = path.join(__dirname, '..', 'tmp', 'database.yml')
      shell.rm '-f', testDB

      @server = new Server( 
        database: testDB 
        logger:   testLogger
      )
      @server.start ->
        done()

    after (done) ->
      @server.stop ->
        done()

    describe 'getStatus', ->
      it 'should be { running: true } if Takana is ON', (done) ->
        @client.getStatus (status) ->
          status.running.should.equal(true)
          done()

    describe 'getProjects', ->
      it 'should list all projects', (done) ->
        @client.getProjects (error, projects) ->
          projects.should.be.empty #.to.eql([])
          done()

    describe 'addProject', ->
      it 'should add a project', (done) ->
        projectPath = fixturePath('scss/foundation')
        # add a project
        @client.addProject {
          name: "testProject"
          path: projectPath
          includePaths: [process.cwd()]
        }, (error) => 

          # callback should return no errors
          (typeof error == 'undefined').should.be.true

          # get the project
          @client.getProjects (error, projects) =>
            projects[0].name.should.equal 'testProject'
            projects[0].path.should.equal projectPath
            projects[0].includePaths.should.eql [process.cwd()]
            done()

      it 'should update project path and includePaths if called for an existing project'

    describe 'removeProject', ->
      it 'should remove a project'



            

  context 'server stopped', ->
    describe 'getStatus', ->
      it 'should be { running: false } is Takana is OFF', (done) ->    
        @client.getStatus (status) ->
          status.running.should.be.false
          done()
  









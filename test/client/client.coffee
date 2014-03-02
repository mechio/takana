Client = require '../../lib/client'
{exec} = require 'child_process'
yaml   = require 'js-yaml'
expect = require('chai').expect

describe 'Client', ->
  beforeEach ->
    @shutdownTimeout = 500 
    @client  = new Client()

  describe 'start', ->
    it 'should start Takana and callback when booted', (done) ->
      @timeout(5000)
      @client.start (status) ->
        status.running.should.equal(true)
        done()

  describe 'getStatus', ->
    it 'should be { running: true } if Takana is ON', (done) ->
      @client.getStatus (status) ->
        status.running.should.equal(true)
        done()

    it 'should be { running: false } is Takana is OFF', (done) ->
      @client.stop()
      setTimeout =>      
        @client.getStatus (status) ->
          status.running.should.be.false
          done()
      , @shutdownTimeout

  describe 'getServerProcess', ->
    it 'should list running Takana processes', (done) ->
      @client.start =>
        @client.getServerProcess (serverProcess) ->
          serverProcess[0].cwd.should.equal(process.cwd())
          serverProcess[0].running.should.equal(true)
          # we should make this test more comprehensive
          #
          done()

  describe 'stop', ->
    it 'should stop Takana', (done) ->
      @client.start (status) =>
        status.running.should.equal.true
        @client.stop()
        setTimeout => 
          @client.getStatus (status) ->
            status.running.should.be.false
            done()
        , @shutdownTimeout

  describe 'getProjects', ->
    it 'should list all projects', (done) ->
      # this could be way better if we have a config file for takana
      # that changes yaml file location for testing
      #
      @client.start =>
        @client.getProjects (error, projects) ->
          expect(projects).to.eql([])
          done()

  describe 'addProject', ->
    it 'should add a project', (done) ->
      @client.start =>

        # add a project
        @client.addProject {
          name: "testProject"
          path: process.cwd()
          includePaths: [process.cwd()]
        }, (error) => 

          # callback should return no errors
          expect(error).to.equal(undefined)

          # get the project
          @client.getProjects (error, projects) =>
            expect(projects[0].name).to.eql("testProject")
            expect(projects[0].path).to.eql(process.cwd())
            expect(projects[0].includePaths).to.eql([process.cwd()])
            done()

      it 'should update project path and includePaths if called for an existing project', ->

  describe 'removeProject', ->
    it 'should remove a project', ->



          














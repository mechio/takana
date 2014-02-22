log     = require '../support/logger'
path    = require 'path'
Project = require './project'
_       = require 'underscore'

class ProjectManager
  constructor: (@options={}) ->
    @logger         = log.getLogger('ProjectManager')
    @projects       = {}
    @editorManager  = @options.editorManager
    @browserManager = @options.browserManager
    @scratchPath    = @options.scratchPath
    @projectDB      = @options.projectDB

    if !@browserManager || !@editorManager || !@scratchPath
      throw('ProjectManager not instantiated with required options')


  add: (options={}) ->
    return if @get(options.name)

    @logger.debug 'adding project', options

    project = new Project(
      path           : options.path
      name           : options.name
      includePaths   : options.includePaths 
      scratchPath    : path.join(@scratchPath, options.path)
      browserManager : @browserManager
      editorManager  : @editorManager
      logger         : log.getLogger("Project[#{options.name}]")
    )
    project.start()
    @projects[project.name] = project
    
  get: (name) -> @projects[name]

  allProjects: ->
    _.values(@projects)

  remove: (name) ->
    if project = @get(name)
      project.stop()
      delete @projects[project.name]

module.exports = ProjectManager

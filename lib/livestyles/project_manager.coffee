log     = require '../support/logger'
path    = require 'path'
Project = require './project'

class ProjectManager
  constructor: (@options={}) ->
    @logger         = log.getLogger('ProjectManager')
    @projects       = {}
    @editorManager  = @options.editorManager
    @browserManager = @options.browserManager
    @scratchPath    = @options.scratchPath

    if !@browserManager || !@editorManager || !@scratchPath
      throw('ProjectManager not instantiated with required options')


  add: (options={}) ->
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


module.exports = ProjectManager

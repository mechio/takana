log       = require '../support/logger'
path      = require 'path'
Project   = require './project'
_         = require 'underscore'
yaml      = require 'js-yaml'
fs        = require 'fs'

class ProjectManager
  constructor: (@options={}) ->
    @logger         = log.getLogger('ProjectManager')
    @projects       = {}
    @editorManager  = @options.editorManager
    @browserManager = @options.browserManager
    @scratchPath    = @options.scratchPath
    @database       = @options.database

    if !@browserManager || !@editorManager || !@scratchPath
      throw('ProjectManager not instantiated with required options')


  add: (options={}) ->
    return if @get(options.name)

    @logger.debug 'adding project', options

    project = new Project(
      path           : options.path
      name           : options.name
      includePaths   : (options.includePaths || [])
      scratchPath    : path.join(@scratchPath, options.path)
      browserManager : @browserManager
      editorManager  : @editorManager
      logger         : log.getLogger("Project[#{options.name}]")#log.getLogger("Project[#{options.name}]")
    )
    project.start()
    @projects[project.name] = project
    @writeDB()
    project

  get: (name) -> @projects[name]

  allProjects: ->
    _.values(@projects)

  remove: (name) ->
    if project = @get(name)
      project.stop()
      delete @projects[project.name]
      @writeDB()

  start: ->
    @readDB() if @database

  stop: ->
    @allProjects().forEach (project) ->
      project.stop()


  readDB: ->
    return unless @database
    @logger.debug "reading project database"
    if fs.existsSync @database
      try 
        doc = yaml.safeLoad(fs.readFileSync(@database, 'utf8'))
        for project in doc.projects
          @add(
            name         : project.name
            path         : project.path
            includePaths : project.includePaths
          )

      catch e
        @logger.error('error reading project database:', e.toString())
  
  writeDB: ->
    return unless @database
    @logger.debug "writing to project database"
    data = 
      projects: 
        @allProjects().map (project) ->
          {
            name         : project.name
            path         : project.path
            includePaths : project.includePaths
          }
    try 
      fs.writeFileSync @database, yaml.safeDump(data), flags: 'w'
    catch e
      @logger.error('error writing project database:', e.toString())


module.exports = ProjectManager

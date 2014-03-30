class Takana.Client
  constructor: ->
    # @scriptTag    = document.querySelectorAll("script[data-project]")[0]
    @projectName            = 'default'#@scriptTag.getAttribute("data-project")
    Takana.Config.port      = 48626
    Takana.Config.hostname  = 'localhost'
                              # if src = @scriptTag.getAttribute('src') 
                              #   parser = document.createElement('a')
                              #   parser.href = src
                              #   parser.hostname
                              # else
                              #   'localhost'
    
    Takana.Server.instance = @server = new Takana.Server projectName: @projectName, =>
      @project = new Takana.Project(name: @projectName)

  @start: ->
    new Takana.Client()
    
window.takana = Takana.Client.start() if typeof(__karma__) == "undefined"

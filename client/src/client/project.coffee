class Takana.Project
  constructor: (attributes) ->
    @name                 = attributes.name
    @documentStyleSheets  = []
    @styleSheets          = {}

    StyleSheetList.prototype.forEach = Array.prototype.forEach

    document.styleSheets.forEach (documentStyleSheet) =>
      if (!!documentStyleSheet.href && (documentStyleSheet.href.match(/^http\:\/\/.*\.css.*/) || documentStyleSheet.href.match(/^file\:\/\/.*/)))
        @documentStyleSheets.push documentStyleSheet

    Takana.Server.instance.bind "stylesheet:resolved", (event) => 
      @documentStyleSheets.forEach (documentStyleSheet) =>
        if event.href == documentStyleSheet.href

          styleSheet = new Takana.StyleSheet(
            documentStyleSheet: documentStyleSheet, 
            id: event.id
          )
          
          @styleSheets[event.id] = styleSheet

          styleSheet.startListening()

    @documentStyleSheets.forEach (styleSheet) => 
      Takana.Server.instance.send "stylesheet:resolve", href: styleSheet.href
    

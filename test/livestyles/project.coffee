describe 'Project', ->

  context 'received folder updated event', ->
    it 'should call handleFolderUpdate'

  context 'received buffer:update event', ->
    it 'should call bufferUpdate on the folder'

  context 'received buffer:reset event', ->
    it 'should call bufferClear on the folder'

  context 'received stylesheet:resolve event', ->
    context 'matching stylesheet', ->
      it 'should callback with the path of the matched stylesheet'

    context 'no matching stylesheet', ->
      it 'should callback with an error'

  describe 'handleFolderUpdate', ->
    it 'should render all watched stylesheets on the project'
    context 'successful render', ->
      it 'should store the rendered body in the bodycache'
      it 'should notify the browser manager'

  describe 'start', ->
    it 'should start watching its folder'




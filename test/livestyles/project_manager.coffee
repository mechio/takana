describe 'ProjectManager', ->
  describe 'add', ->
    it 'should add a new project to its internal representation'
    it 'should start the project'
    it 'should add the project to the database'
    context 'name taken', ->
      it "shouldn't add it"

  describe 'remove', ->
    it 'should remove the project from its internal representation'
    it 'should remove the project from the database'

  describe 'constructor', ->
    it 'should load all projects from the database'

  describe 'get', ->
    context 'with name', ->
      it 'should return the project'

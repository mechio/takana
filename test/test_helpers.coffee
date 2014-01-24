path = require 'path'


global.fixturePath = (fixture) -> 
  path.join(__dirname, 'fixtures', fixture)

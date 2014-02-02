yaml  = require('js-yaml')
fs    = require('fs')

exports.loadConfig = (path) ->
  try 
    return yaml.safeLoad(fs.readFileSync(path, 'utf8'))
  catch (e)
    return null
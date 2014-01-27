
helpers    = require('./helpers')
shell      = require('shelljs')

supportDir      = helpers.expandPath('~/.takana')
projectIndexDir = helpers.expandPath('~/.takana/projects')
scratchDir      = helpers.expandPath('~/.takana/scratch')

# shell.mkdir('-p', supportDir)
# shell.mkdir('-p', projectIndexDir)
# shell.mkdir('-p', scratchDir)

# helpers.resolveSymlinksInDirectory projectIndexDir, ->
#   console.log arguments



renderer = require('./renderer')


exports.helpers = helpers




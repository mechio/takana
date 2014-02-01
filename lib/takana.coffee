
helpers    = require('./helpers')
shell      = require('shelljs')

supportDir      = helpers.sanitizePath('~/.takana')
projectIndexDir = helpers.sanitizePath('~/.takana/projects')
scratchDir      = helpers.sanitizePath('~/.takana/scratch')

# shell.mkdir('-p', supportDir)
# shell.mkdir('-p', projectIndexDir)
# shell.mkdir('-p', scratchDir)

# helpers.resolveSymlinksInDirectory projectIndexDir, ->
#   console.log arguments



renderer = require('./renderer')


exports.helpers = helpers




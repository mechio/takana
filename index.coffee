takana  = require './lib/core'
helpers = require './lib/support/helpers'


core = new takana.Core(
  editorPort    : 48627
  httpPort      : 48626
  scratchPath   : helpers.sanitizePath('~/.takana/scratch')
  projectDB     : helpers.sanitizePath('~/.takana/projects.yaml')
)

core.start()






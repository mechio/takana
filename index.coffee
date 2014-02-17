takana  = require('./lib/takana')



core = new takana.Core(
  editorPort    : 48627
  httpPort      : 48626
  scratchPath   : takana.helpers.sanitizePath('~/.takana/scratch')
  projectDB     : takana.helpers.sanitizePath('~/.takana/projects.yaml')
)

core.start()






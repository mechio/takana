Q          = require 'q'
fs         = require 'fs'
path       = require 'path'
_          = require 'underscore'
url        = require 'url'
algo       = require './algo'
{exec}     = require 'child_process'
shell      = require 'shelljs'
logger     = require './logger'

exports.guid = ->
  "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace /[xy]/g, (c) ->
    r = Math.random() * 16 | 0
    v = (if c is "x" then r else (r & 0x3 | 0x8))
    v.toString 16


exports.fastFind = (path, extensions, callback) ->
  p   = sanitizePath(path)
  p   = p.substring(0, p.length - 1);

  cmd = "find #{p} " + extensions.map( (e) -> "-name '*.#{e}'" ).join(' -o ')

  exec cmd, (error, stdout, stderr) =>
    files = stdout.trim().split("\n")

    callback?(error, files)


# implmentation of Java's String hashcode
exports.hashCode = (string) ->
  hash = 0
  return hash if string.length is 0
  i = 0
  l = string.length

  while i < l
    char = string.charCodeAt(i)
    hash = ((hash << 5) - hash) + char
    hash |= 0 # Convert to 32bit integer
    i++
  hash


# pipes event from eventemitter a through eventemitter b
exports.pipeEvent = (event, a, b) ->
  a.on event, ->
    args = Array.prototype.slice.call(arguments)
    args.unshift(event)
    b.emit.apply(b, args)

# Given a path, returns it's extension, without the leading .
exports.extname = extname = (filePath) ->
  path.extname(filePath).replace('.', '')

# Given a file path and a extension list, 
# returns true if the file is of one of the given types 
exports.isFileOfType = isFileOfType = (p, types) ->
  types = [types] if typeof types == 'string'
  types.indexOf(extname(p)) != -1

# Given a path: 
#   1. ensures that it has a trailing slash
#   2. resolves ~ to the full path of the home directory
exports.sanitizePath = sanitizePath = (p) ->
  if (p.substr(0,1) == '~')
    p = process.env.HOME + p.substr(1)

  p = path.resolve(p)
  if /.*\/$/.test(p) then p else p + "/"

# Easily create a timer
exports.measureTime = measureTime = ->
  startTime   = Date.now()
  {
    elapsed: -> Date.now() - startTime
  }


#
# Stylesheet Helpers
#
exports.pathToSequence = pathToSequence = (p) ->
  seq                 = _.reject p.split('/'), (c) -> c == ''
  seq[seq.length - 1] = path.basename(seq[seq.length - 1]).replace(path.extname(seq[seq.length - 1]), '')
  seq

exports.basename = basename = (p) ->
  path.basename(p).replace(path.extname(p), '').split('.')[0]


exports.absolutizeUrls = (body, href) ->
  urlRegex = ///
    url\(
      [\"|\']{0,1}
      ([^\)|^\"|^\']+)
      [\"|\']{0,1}
    \)                  # 
  ///g
  joinUrl  = url.resolve
  protocol = url.parse(href).protocol
  body = body.replace urlRegex, (m, url) ->
    url = protocol + url if /^\/\/.*/.test(url)
    url = joinUrl(href, url)   
    "url('#{url}')"
  body

exports.pickBestFileForHref = (href, candidates) ->
  findBestFile url.parse(href).path, candidates

exports.findBestFile = findBestFile = (filePath, candidates) ->
  basename   = exports.basename(filePath)
  regexp = ".*#{basename}[^\/]\.*$"
  candidates = _.select candidates, (c) -> new RegExp(regexp).test(c)

  # remove all partials
  candidates = _.reject candidates, (c) -> path.basename(c)[0] == '_'

  if candidates.length == 1
    # If there is only one match, pick that one
    return candidates[0]
  else if candidates.length == 0
    return null
  else 
    # reject all css
    candidatesNoCss = _.reject candidates, (c) -> path.extname(c) == '.css'
    if candidatesNoCss.length == 1
      return candidatesNoCss[0]
    else
      # Build an array of tuples, each tuple is of the format: <candidate, score>
      # where score is algo.lcsLength
      tuples = candidates.map (c) ->
        hrefSeq      = pathToSequence(filePath)
        candidateSeq = pathToSequence(c)
        [c, algo.lcsLength(hrefSeq, candidateSeq)]

      # Find our candidate, the tuple with the highest score
      tuples    = _.sortBy tuples, (c) -> c[1]

      best      = _.last(tuples) 

      bestScore = best[1]
      if _.select(tuples, (t) -> t[1] == bestScore).length == 1
        # If the candidate has a unique high score, choose it
        return best[0]
        
  candidates


exports.installSublimePlugin = ->

  logger = logger.getLogger('sublimeInstaller')

  st2PackagePath    = sanitizePath('~/Library/Application Support/Sublime Text 2/Packages/')
  st3PackagePath    = sanitizePath('~/Library/Application Support/Sublime Text 3/Packages/')
  takanaPackagePath = null 

  if fs.existsSync(st3PackagePath)
    takanaPackagePath = path.join(st3PackagePath, 'Takana')
    logger.info "found Sublime Text 3"
  else if fs.existsSync(st2PackagePath)
    takanaPackagePath = path.join(st2PackagePath, 'Takana')
    logger.info "found Sublime Text 2"
  else 
    logger.error "couldn't find a Sublime Text installation"
    return
    
  logger.info "installing plugin to '%s'", takanaPackagePath
  shell.mkdir('-p', takanaPackagePath)
  shell.cp '-f', path.join(__dirname, '../../sublime-plugin/takana.py'), path.join(takanaPackagePath, 'takana.py')

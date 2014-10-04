Q           = require 'q'
fs          = require 'fs'
path        = require 'path'
_           = require 'underscore'
url         = require 'url'
{exec}      = require 'child_process'
shell       = require 'shelljs'
logger      = require './logger'
FileMatcher = require './file_matcher'

guid = ->
  "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace /[xy]/g, (c) ->
    r = Math.random() * 16 | 0
    v = (if c is "x" then r else (r & 0x3 | 0x8))
    v.toString 16


fastFind = (path, extensions, callback) ->
  p   = sanitizePath(path)
  p   = p.substring(0, p.length - 1);

  cmd = "find #{p} " + extensions.map( (e) -> "-name '*.#{e}'" ).join(' -o ')

  exec cmd, (error, stdout, stderr) =>
    files = stdout.trim().split("\n")

    callback?(error, files)


# implmentation of Java's String hashcode
hashCode = (string) ->
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
pipeEvent = (event, a, b) ->
  a.on event, ->
    args = Array.prototype.slice.call(arguments)
    args.unshift(event)
    b.emit.apply(b, args)

# Given a path, returns it's extension, without the leading .
extname = (filePath) ->
  path.extname(filePath).replace('.', '')


# Given a file path and a extension list,
# returns true if the file is of one of the given types
isFileOfType = (p, types) ->
  types = [types] if typeof types == 'string'
  types.indexOf(extname(p)) != -1


# Given a path:
#   1. ensures that it has a trailing slash
#   2. resolves ~ to the full path of the home directory
sanitizePath = (p) ->
  if (p.substr(0,1) == '~')
    p = process.env.HOME + p.substr(1)

  p = path.resolve(p)
  if /.*\/$/.test(p) then p else p + "/"


# Easily create a timer
measureTime = ->
  startTime   = Date.now()
  {
    elapsed: -> Date.now() - startTime
  }

absolutizeUrls = (body, href) ->
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

pickBestFileForHref = (href, candidates) ->
  FileMatcher.pickBestFileForHref(href, candidates)

module.exports =
  guid: guid
  fastFind: fastFind
  hashCode: hashCode
  pipeEvent: pipeEvent
  extname: extname
  isFileOfType: isFileOfType
  sanitizePath: sanitizePath
  measureTime: measureTime
  absolutizeUrls: absolutizeUrls
  pickBestFileForHref: pickBestFileForHref

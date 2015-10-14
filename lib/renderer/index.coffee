css     = require './css'
scss    = require './scss'
less    = require './less'
helpers = require '../support/helpers'
_       = require 'underscore'

renderers = 
  css  : css
  scss : scss
  sass : scss
  less : less

exports.for = (file) ->
  extension = helpers.extname(file)
  renderers[extension]

exports.supportedExtensions = ->
  _.keys(renderers)

module.exports = _.extend(module.exports, renderers)
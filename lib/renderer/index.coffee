css     = require './css'
scss    = require './scss'
helpers = require '../support/helpers'
_       = require 'underscore'

renderers = 
  css  : css
  scss : scss

exports.for = (file) ->
  extension = helpers.extname(file)
  renderers[extension]

exports.supportedExtensions = ->
  _.keys(renderers)

module.exports = _.extend(module.exports, renderers)
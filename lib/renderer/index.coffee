css     = require './css'
scss    = require './scss'
helpers = require '../helpers'
_       = require 'underscore'

renderers = 
  css  : css
  scss : scss

exports.for = (file) ->
  extension = helpers.extname(file)
  renderers[extension]

module.exports = _.extend(module.exports, renderers)
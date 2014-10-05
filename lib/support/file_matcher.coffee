path       = require 'path'
_          = require 'underscore'
url        = require 'url'
algo       = require './algo'
logger     = require './logger'

class FileMatcher

  @pathToSequence: (p) ->
    seq                 = _.reject p.split('/'), (c) -> c == ''
    seq[seq.length - 1] = path.basename(seq[seq.length - 1]).replace(path.extname(seq[seq.length - 1]), '')
    seq

  @basename: (p) ->
    path.basename(p).replace(path.extname(p), '').split('.')[0]

  @pickBestFileForHref: (href, candidates) ->
    @findBestFile url.parse(href).path, candidates

  @candidatesWithoutPartials: (filePath, candidates) ->
    basename   = @basename(filePath)
    regexp     = ".*#{basename}[^\/]\.*$"
    candidates = _.select candidates, (c) -> new RegExp(regexp).test(c)
    # strip partials
    candidates = _.reject candidates, (c) -> path.basename(c)[0] == '_'


  @candidatesWithoutPlainCss: (candidates) ->
    _.reject candidates, (c) -> path.extname(c) == '.css'

  @candidatesWithExactFilename: (filePath, candidates) ->
    that = @
    _.select candidates, (t) -> that.basename(t) == that.basename(filePath)

  @scoredMatching: (filePath, candidates) ->
    that       = @
    # Build an array of tuples, each tuple is of the format: <candidate, score>
    # where score is algo.lcsLength
    tuples = candidates.map (c) ->
      hrefSeq      = that.pathToSequence(filePath)
      candidateSeq = that.pathToSequence(c)
      [c, algo.lcsLength(hrefSeq, candidateSeq)]

    # Find our candidate, the tuple with the highest score
    tuples    = _.sortBy tuples, (c) -> c[1]
    best      = _.last(tuples)

    # If the candidate has a unique high score, choose it
    bestScore = best[1]
    bestOnes  = _.select(tuples, (t) -> t[1] == bestScore )
    return bestOnes[0][0] if bestOnes.length == 1

    # now try without css files, if possible
    bestOnesNoCss = _.reject bestOnes, (t) -> path.extname(t[0]) == '.css'
    return bestOnesNoCss[0][0] if bestOnesNoCss.length == 1


  @candidatesWithSimilarEnding: (filePath, candidates) ->
    _.select candidates, (t) => 
      t = t.replace(/scss/g, 'css')
      t.indexOf(filePath) == t.length - filePath.length

  @findBestFile: (filePath, candidates) ->
    candidates = @candidatesWithoutPartials(filePath, candidates)

    # if only one or less, return first / null
    return (candidates[0]||null) if candidates.length < 2

    candidatesNoCss = @candidatesWithoutPlainCss(candidates)
    return candidatesNoCss[0] if candidatesNoCss.length == 1

    exactFilename   = @candidatesWithExactFilename(filePath, candidates)
    return exactFilename[0] if exactFilename.length == 1

    similarEnding = @candidatesWithSimilarEnding(filePath, candidatesNoCss)
    return similarEnding[0] if similarEnding.length == 1    

    scored = @scoredMatching(filePath, candidates)
    return scored if scored

    candidates

  @logObject:  (msg, obj)->
    console.log(msg)
    if _.isObject(obj)
      console.log(_.pairs(obj))
    else
      console.log(obj)

module.exports =
  FileMatcher = FileMatcher
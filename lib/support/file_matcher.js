import path from 'path';
import _ from 'underscore';
import url from 'url';
import algo from './algo';
import logger from './logger';

export default class FileMatcher {

  static pathToSequence(p) {
    let seq                 = _.reject(p.split('/'), c => c === '');
    seq[seq.length - 1] = path.basename(seq[seq.length - 1]).replace(path.extname(seq[seq.length - 1]), '');
    return seq;
  }

  static basename(p) {
    return path.basename(p).replace(path.extname(p), '').split('.')[0];
  }

  static pickBestFileForHref(href, candidates) {
    return this.findBestFile(url.parse(href).path, candidates);
  }

  static candidatesWithoutPartials(filePath, candidates) {
    let basename   = this.basename(filePath);
    let regexp     = `.*${basename}[^\/]\.*$`;
    candidates = _.select(candidates, c => new RegExp(regexp).test(c));
    // strip partials
    return candidates = _.reject(candidates, c => path.basename(c)[0] === '_');
  }


  static candidatesWithoutPlainCss(candidates) {
    return _.reject(candidates, c => path.extname(c) === '.css');
  }

  static candidatesWithExactFilename(filePath, candidates) {
    let that = this;
    return _.select(candidates, t => that.basename(t) === that.basename(filePath));
  }

  static scoredMatching(filePath, candidates) {
    let that       = this;
    // Build an array of tuples, each tuple is of the format: <candidate, score>
    // where score is algo.lcsLength
    let tuples = candidates.map(function(c) {
      let hrefSeq      = that.pathToSequence(filePath);
      let candidateSeq = that.pathToSequence(c);
      return [c, algo.lcsLength(hrefSeq, candidateSeq)];
    });

    // Find our candidate, the tuple with the highest score
    tuples    = _.sortBy(tuples, c => c[1]);
    let best      = _.last(tuples);

    // If the candidate has a unique high score, choose it
    let bestScore = best[1];
    let bestOnes  = _.select(tuples, t => t[1] === bestScore );
    if (bestOnes.length === 1) { return bestOnes[0][0]; }

    // now try without css files, if possible
    let bestOnesNoCss = _.reject(bestOnes, t => path.extname(t[0]) === '.css');
    if (bestOnesNoCss.length === 1) { return bestOnesNoCss[0][0]; }
  }


  static candidatesWithSimilarEnding(filePath, candidates) {
    return _.select(candidates, t => { 
      t = t.replace(/scss/g, 'css');
      return t.indexOf(filePath) === t.length - filePath.length;
    });
  }

  static findBestFile(filePath, candidates) {
    candidates = this.candidatesWithoutPartials(filePath, candidates);

    // if only one or less, return first / null
    if (candidates.length < 2) { return (candidates[0]||null); }

    let candidatesNoCss = this.candidatesWithoutPlainCss(candidates);
    if (candidatesNoCss.length === 1) { return candidatesNoCss[0]; }

    let exactFilename   = this.candidatesWithExactFilename(filePath, candidates);
    if (exactFilename.length === 1) { return exactFilename[0]; }

    let similarEnding = this.candidatesWithSimilarEnding(filePath, candidatesNoCss);
    if (similarEnding.length === 1) { return similarEnding[0]; }    

    let scored = this.scoredMatching(filePath, candidates);
    if (scored) { return scored; }

    return candidates;
  }

  static logObject(msg, obj){
    console.log(msg);
    if (_.isObject(obj)) {
      return console.log(_.pairs(obj));
    } else {
      return console.log(obj);
    }
  }
}
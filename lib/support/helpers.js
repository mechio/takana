import Q from 'q';
import fs from 'fs';
import path from 'path';
import _ from 'underscore';
import {spawn} from 'child_process';
import shell from 'shelljs';
import logger from './logger';
import FileMatcher from './file_matcher';
import url from 'url';

let guid = function() {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function(c) {
    var r, v;
    r = Math.random() * 16 | 0;
    v = (c === "x" ? r : r & 0x3 | 0x8);
    return v.toString(16);
  });
};

let fastFind = function(path, extensions, callback) {
  var args, find, p, stdout;
  p = sanitizePath(path);
  p = p.substring(0, p.length - 1);
  args = (p + " ") + extensions.map(function(e) {
    return "-name *." + e;
  }).join(' -o ');
  find = spawn('find', args.split(' '));
  stdout = "";
  find.stdout.on('data', function(data) {
    return stdout += data;
  });
  find.on('error', function(e) {
    if (callback) {
      return callback(e);
    }
  });
  return find.on('close', function(code) {
    var files;
    files = stdout.trim().split("\n");
    if (callback) {
      return callback(null, files);
    }
  });
};

let pipeEvent = function(event, a, b) {
  return a.on(event, function() {
    var args;
    args = Array.prototype.slice.call(arguments);
    args.unshift(event);
    return b.emit.apply(b, args);
  });
};

let extname = function(filePath) {
  return path.extname(filePath).replace('.', '');
};

let isFileOfType = function(p, types) {
  if (typeof types === 'string') {
    types = [types];
  }
  return types.indexOf(extname(p)) !== -1;
};

let sanitizePath = function(p) {
  if (p.substr(0, 1) === '~') {
    p = process.env.HOME + p.substr(1);
  }
  p = path.resolve(p);
  if (/.*\/$/.test(p)) {
    return p;
  } else {
    return p + "/";
  }
};

let measureTime = function() {
  var startTime;
  startTime = Date.now();
  return {
    elapsed: function() {
      return Date.now() - startTime;
    }
  };
};

let pickBestFileForHref = function(href, candidates) {
  return FileMatcher.pickBestFileForHref(href, candidates);
};

module.exports = {
  guid: guid,
  fastFind: fastFind,
  pipeEvent: pipeEvent,
  extname: extname,
  isFileOfType: isFileOfType,
  sanitizePath: sanitizePath,
  measureTime: measureTime,
  pickBestFileForHref: pickBestFileForHref
};


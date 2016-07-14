import path from 'path';
import shell from 'shelljs';
import checksum from 'checksum';
import Q from 'q';
import fs from 'fs';
import glob from 'glob';
import assert from 'assert';
import logger from '../lib/support/logger';
import Log4js from 'log4js';
import should from 'should';

Log4js.setGlobalLogLevel(Log4js.levels.OFF);

global.testLogger = logger.getLogger('Test');

global.fixturePath = fixture => path.join(__dirname, 'fixtures', fixture);

global.createEmptyTmpDir = function(suffix='') {
  let tmpDir = path.join(__dirname, '..', 'tmp', `test${suffix}`);
  shell.mkdir('-p', tmpDir);
  shell.rm('-rf', path.join(tmpDir, '*'));
  return tmpDir;
};

global.assertFilesSame = (file1, file2, done) =>
  Q.nfcall(checksum.file, file1)
    .then(hash1 =>
      Q.nfcall(checksum.file, file2)
        .then(hash2 => [hash1, hash2])
    )
    .spread(function(hash1, hash2) {
      hash1.should.equal(hash2);
      if (done) { 
        return done();
      }
    })
    .fail(function(e) {
      throw e;
    })
    .done()
;

global.assertFileHasBody = (file, body, done) =>
  checksum.file(file, function(e, hash1) {
    hash1.should.equal(checksum(body));
    if (done) {
      return done();
    }
  })
;

global.assertIsFolder = (existance, folder, done) =>
  Q.nfcall(fs.lstat, folder)
    .then(function(stats) {
      stats.isDirectory().should.equal(existance);
      if (done) {
        return done();
      }
    })
    .fail(function(e) {
      throw e;
    })
    .done()
;

global.assertFileExistance = (existance, file, done) =>
  fs.exists(file, function(exists) {
    (!!exists).should.equal(existance);
    if (done) {
      return done();
    }
  })
;

global.assertFoldersEqual = (pattern, folder1, folder2, done) =>
  Q.nfcall(glob, path.join(folder1, pattern))
    .then(files1 =>
      Q.nfcall(glob, path.join(folder2, pattern))
        .then(function(files2) {
          files1 = files1.map(f => f.replace(folder1, ''));
          files2 = files2.map(f => f.replace(folder2, ''));
          assert.deepEqual(files1, files2);
          if (done) {
            return done();
          }
        })
    )
    .fail(function(e) {
      throw e;
    })
    .done()
;

global.assertFolderEmpty = (folder, done) =>
  glob(path.join(folder, '**/**'), function(e, files) {
    assert.deepEqual(files, [folder]);
    if (done) {
      return done();
    }
  })
;


//
//  These should all pass
//
// import 'should';
//
// assertFilesSame fixturePath('test_helpers/index.html'), fixturePath('test_helpers/index.html-copy')
// assertFileHasBody fixturePath('test_helpers/small'), "hello, my name is poo poo\n"

// assertIsFolder(true, fixturePath('test_helpers/empty'))
// assertIsFolder(false, fixturePath('test_helpers/small'))

// assertFileExistance(false, fixturePath('test_helpers/blah'))
// assertFileExistance(true, fixturePath('test_helpers/small'))

// assertFoldersEqual('**/**', fixturePath('test_helpers/foundation'), fixturePath('test_helpers/foundation-copy'))

// assertFolderEmpty(fixturePath('test_helpers/empty'))

path     = require 'path'
shell    = require 'shelljs'
checksum = require 'checksum'
Q        = require 'q'
fs       = require 'fs'
glob     = require 'glob'
assert   = require 'assert'
logger   = require '../lib/support/logger'
Log4js   = require 'log4js'

Log4js.setGlobalLogLevel(Log4js.levels.OFF)

global.testLogger = logger.getLogger('Test')

global.fixturePath = (fixture) -> 
  path.join(__dirname, 'fixtures', fixture)

global.createEmptyTmpDir = (suffix='') ->
  tmpDir = path.join(__dirname, '..', 'tmp', 'test' + suffix)  
  shell.mkdir('-p', tmpDir)
  shell.rm('-rf', path.join(tmpDir, '*'))
  tmpDir

global.assertFilesSame = (file1, file2, done) ->
  Q.nfcall(checksum.file, file1)
    .then (hash1) ->  
      Q.nfcall(checksum.file, file2)
        .then (hash2) ->
          [hash1, hash2]
    .spread (hash1, hash2) ->
      hash1.should.equal(hash2)
      done?()            
    .fail (e) ->
      throw e
    .done()

global.assertFileHasBody = (file, body, done) ->
  checksum.file file, (e, hash1) ->
    hash1.should.equal(checksum(body))
    done?()
  
global.assertIsFolder = (existance, folder, done) ->
  Q.nfcall(fs.lstat, folder)
    .then (stats) ->
      stats.isDirectory().should.equal(existance)
      done?()            
    .fail (e) ->
      throw e
    .done()

global.assertFileExistance = (existance, file, done) ->
  fs.exists file, (exists) ->
    (!!exists).should.equal(existance)
    done?()            

global.assertFoldersEqual = (pattern, folder1, folder2, done) ->
  Q.nfcall(glob, path.join(folder1, pattern))
    .then (files1) ->
      Q.nfcall(glob, path.join(folder2, pattern))
        .then (files2) ->
          files1 = files1.map (f) -> f.replace(folder1, '')
          files2 = files2.map (f) -> f.replace(folder2, '')
          assert.deepEqual(files1, files2)
          done?()
    .fail (e) ->
      throw e
    .done()

global.assertFolderEmpty = (folder, done) ->
  glob path.join(folder, '**/**'), (e, files) ->
    assert.deepEqual(files, [folder])
    done?()


# 
#  These should all pass
# 
require 'should'
#
# assertFilesSame fixturePath('test_helpers/index.html'), fixturePath('test_helpers/index.html-copy')
# assertFileHasBody fixturePath('test_helpers/small'), "hello, my name is poo poo\n"

# assertIsFolder(true, fixturePath('test_helpers/empty'))
# assertIsFolder(false, fixturePath('test_helpers/small'))

# assertFileExistance(false, fixturePath('test_helpers/blah'))
# assertFileExistance(true, fixturePath('test_helpers/small'))

# assertFoldersEqual('**/**', fixturePath('test_helpers/foundation'), fixturePath('test_helpers/foundation-copy'))

# assertFolderEmpty(fixturePath('test_helpers/empty'))

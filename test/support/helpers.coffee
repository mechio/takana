helpers = require '../../lib/support/helpers'

describe 'helpers', ->
  describe 'sanitizePath', ->
    it 'should expand the tilde path', ->
      helpers.sanitizePath('~').should.equal(process.env.HOME + '/')
      helpers.sanitizePath('~/.takana/projects/').should.equal(process.env.HOME + '/.takana/projects/')

    it 'should add a trailing slash', ->
      helpers.sanitizePath('/path/to/something').should.equal('/path/to/something/')      

  describe 'extname', ->
    it 'should return the extension of a file', ->
      helpers.extname('/path/to/some/file.css').should.equal('css')
      helpers.extname('/path/to/some/file.scss').should.equal('scss')

  describe 'isFileOfType', ->
    it 'should return true if the file is one of the types', ->
      helpers.isFileOfType('/path/to/blah.scss', ['scss']).should.be.true

    it 'should return false if the file is not one of the types', ->
      helpers.isFileOfType('/path/to/blah.scss', ['css']).should.be.false

  describe 'fastFind', ->
    it 'should have the same output as glob'


  describe 'absolutizeUrls', ->
    it "should absolutize all urls in a template", ->
      style = """
        .el1 {
          background-image: url(path/to/some/image.png);
        }

        .el2 {
          background-image: url('/path/to/some/image.png');
        }

        .el3 {
          background-image: url(//cake.com/some/crazy/image.png);
        }

        .el4 {
          background-image: url(http://pooter.com/some/crazy/image.png);
        }
      """
      href = "https://jahrasta.com/jah/is/the/most/high/style.css"

      expected = """
        .el1 {
          background-image: url('https://jahrasta.com/jah/is/the/most/high/path/to/some/image.png');
        }

        .el2 {
          background-image: url('https://jahrasta.com/path/to/some/image.png');
        }

        .el3 {
          background-image: url('https://cake.com/some/crazy/image.png');
        }

        .el4 {
          background-image: url('http://pooter.com/some/crazy/image.png');
        }
      """

      helpers.absolutizeUrls(style, href).should.equal(expected)

  describe 'basename', ->
    it "should return the filename of a path without the extension", ->
      helpers.basename('/some/file/somewhere/else.scss').should.equal('else')
      helpers.basename('/some/file/somewhere/else.css.scss').should.equal('else')      
      helpers.basename('/some/file/somewhere/jah.poo').should.equal('jah')

  describe 'pathToSequence()', ->
    it "should convert a path to sequence omitting extensions", ->
      helpers.pathToSequence('/some/file/somewhere.css').should.eql(['some', 'file', 'somewhere'])
      helpers.pathToSequence('/some/file/somewhere/else.scss').should.eql(['some', 'file', 'somewhere', 'else'])
      helpers.pathToSequence('/some/file/somewhere/else').should.eql(['some', 'file', 'somewhere', 'else'])      


  describe 'pickBestFileForHref', ->

    it 'should return the only match if there is just one candidate', ->
      href       = 'http://foundation.dev/scss/style.css?jjhs=sfd'
      candidates = [ 
        '/Users/barnaby/Documents/foundation/css/style.css'
      ]
      match = helpers.pickBestFileForHref href, candidates
      match.should.equal(candidates[0])


    it 'should return null on empty candidates', ->
      href       = 'http://foundation.dev/scss/style.css?jjhs=sfd'
      candidates = []
      match = helpers.pickBestFileForHref href, candidates
      (match == null).should.be.true

    it 'should prioritize scss', ->
      href       = 'http://foundation.dev/scss/style.css?jjhs=sfd'
      candidates = [ 
        '/Users/barnaby/Documents/foundation/css/style.css'
        '/Users/barnaby/Documents/foundation/scss/style.scss' 
      ]
      match = helpers.pickBestFileForHref href, candidates
      match.should.equal('/Users/barnaby/Documents/foundation/scss/style.scss')

    it 'should work with file urls', ->
      href       = 'file://localhost/deep/root/style.css?jjhs=sfd'
      candidates = [ 
        '/Users/barnaby/Documents/foundation/scss/deep/root/style.scss' 
        '/Users/barnaby/Documents/foundation/scss/not/root/style.scss' 
        '/Users/barnaby/Documents/foundation/scss/style.scss' 
      ]
      match = helpers.pickBestFileForHref href, candidates
      match.should.equal('/Users/barnaby/Documents/foundation/scss/deep/root/style.scss')


    it 'should work with less files', ->
      href       = 'http://foundation.dev/deep/root/style.css'
      candidates = [ 
        '/Users/barnaby/Documents/foundation/scss/deep/root/style.less' 
      ]
      match = helpers.pickBestFileForHref href, candidates
      match.should.equal('/Users/barnaby/Documents/foundation/scss/deep/root/style.less')


    it 'should always choose the path that has the longest common subsequence of paths', ->
      href       = 'http://foundation.dev/deep/root/style.css'
      candidates = [ 
        '/Users/barnaby/Documents/foundation/scss/deep/root/style.scss' 
        '/Users/barnaby/Documents/foundation/scss/not/root/style.scss' 
        '/Users/barnaby/Documents/foundation/scss/style.scss' 
      ]
      match = helpers.pickBestFileForHref href, candidates
      match.should.equal('/Users/barnaby/Documents/foundation/scss/deep/root/style.scss')

    it 'should return all candidates if it can not match', ->
      href       = 'http://foundation.dev/style.css'
      candidates = [ 
        '/Users/barnaby/Documents/foundation/unmatcheable1/style.scss' 
        '/Users/barnaby/Documents/foundation/unmatcheable2/style.scss' 
      ]
      match = helpers.pickBestFileForHref href, candidates
      match.should.eql(candidates)

    it 'should match files of type .css.scss', ->
      href       = 'http://yourgrind.dev/home.css'
      candidates = [
        '/Users/nc/Workspace/yourgrind/app/assets/templates/home.css.scss',
        '/Users/nc/Workspace/yourgrind/app/assets/templates/application.css.scss'
      ]
      match = helpers.pickBestFileForHref href, candidates
      match.should.equal('/Users/nc/Workspace/yourgrind/app/assets/templates/home.css.scss')

    it 'should do somewhere', ->
      href = 'http://localhost:3000/styles/app.css'
      candidates = [ 
        '/Users/barnaby/Projects/worldpay-backend/www/build/styles/app.css',
        '/Users/barnaby/Projects/worldpay-backend/www/source/styles/app.scss',
        '/Users/barnaby/Projects/worldpay-backend/www/source/styles/bourbon/css3/_appearance.scss' 
      ]
      match = helpers.pickBestFileForHref href, candidates      
      match.should.equal('/Users/barnaby/Projects/worldpay-backend/www/source/styles/app.scss')

    it 'should always choose the .scss file', ->
      href = "http://mac.dev/build/templates/panel.css"
      candidates = [ 
        '/panel.scss',
        '/panel/_choose_template.scss',
      ]
      match = helpers.pickBestFileForHref href, candidates
      match.should.equal("/panel.scss")


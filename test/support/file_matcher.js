import FileMatcher from '../../lib/support/file_matcher';

describe('FileMatcher', function() {
  describe('basename', () =>
    it("should return the filename of a path without the extension", function() {
      FileMatcher.basename('/some/file/somewhere/else.scss').should.equal('else');
      FileMatcher.basename('/some/file/somewhere/else.css.scss').should.equal('else');
      return FileMatcher.basename('/some/file/somewhere/jah.poo').should.equal('jah');
    })
  );

  describe('pathToSequence()', () =>
    it("should convert a path to sequence omitting extensions", function() {
      FileMatcher.pathToSequence('/some/file/somewhere.css').should.eql(['some', 'file', 'somewhere']);
      FileMatcher.pathToSequence('/some/file/somewhere/else.scss').should.eql(['some', 'file', 'somewhere', 'else']);
      return FileMatcher.pathToSequence('/some/file/somewhere/else').should.eql(['some', 'file', 'somewhere', 'else']);
    })
  );


  describe('pickBestFileForHref', function() {

    it('should do somewhere', function() {
      let href       = 'http://localhost:8000/css/app.css';
      let candidates = [ 
        '/Users/barnaby/Dropbox/Projects/lib/foundation-libsass-template/css/app.css',
        '/Users/barnaby/Dropbox/Projects/lib/foundation-libsass-template/scss/app.scss',         
        '/Users/barnaby/Dropbox/Projects/lib/foundation-libsass-template/node_modules/node-sass/test/sass-spec/spec/basic/50_wrapped_pseudo_selectors/input.scss',
        '/Users/barnaby/Dropbox/Projects/lib/foundation-libsass-template/node_modules/node-sass/test/sass-spec/spec/libsass/append/expected_output.css',
        '/Users/barnaby/Dropbox/Projects/lib/foundation-libsass-template/node_modules/node-sass/test/sass-spec/spec/libsass/append/input.scss',
      ];

      let match = FileMatcher.pickBestFileForHref(href, candidates);
      match.should.equal(candidates[1]);
    });

    it('should return the only match if there is just one candidate', function() {
      let href       = 'http://foundation.dev/scss/style.css?jjhs=sfd';
      let candidates = [
        '/Users/barnaby/Documents/foundation/css/style.css'
      ];
      let match = FileMatcher.pickBestFileForHref(href, candidates);
      match.should.equal(candidates[0]);
    });


    it('should return null on empty candidates', function() {
      let href       = 'http://foundation.dev/scss/style.css?jjhs=sfd';
      let candidates = [];
      let match = FileMatcher.pickBestFileForHref(href, candidates);
      (match === null).should.be.true;
    });

    it('should prioritize scss', function() {
      let href       = 'http://foundation.dev/scss/style.css?jjhs=sfd';
      let candidates = [
        '/Users/barnaby/Documents/foundation/css/style.css',
        '/Users/barnaby/Documents/foundation/scss/style.scss'
      ];
      let match = FileMatcher.pickBestFileForHref(href, candidates);
      match.should.equal('/Users/barnaby/Documents/foundation/scss/style.scss');
    });

    it('should work with file urls', function() {
      let href       = 'file://localhost/deep/root/style.css?jjhs=sfd';
      let candidates = [
        '/Users/barnaby/Documents/foundation/scss/deep/root/style.scss',
        '/Users/barnaby/Documents/foundation/scss/not/root/style.scss',
        '/Users/barnaby/Documents/foundation/scss/style.scss'
      ];
      let match = FileMatcher.pickBestFileForHref(href, candidates);
      match.should.equal('/Users/barnaby/Documents/foundation/scss/deep/root/style.scss');
    });


    it('should work with less files', function() {
      let href       = 'http://foundation.dev/deep/root/style.css';
      let candidates = [
        '/Users/barnaby/Documents/foundation/scss/deep/root/style.less'
      ];
      let match = FileMatcher.pickBestFileForHref(href, candidates);
      match.should.equal('/Users/barnaby/Documents/foundation/scss/deep/root/style.less');
    });


    it('should always choose the path that has the longest common subsequence of paths', function() {
      let href       = 'http://foundation.dev/deep/root/style.css';
      let candidates = [
        '/Users/barnaby/Documents/foundation/scss/deep/root/style.scss',
        '/Users/barnaby/Documents/foundation/scss/not/root/style.scss',
        '/Users/barnaby/Documents/foundation/scss/style.scss'
      ];
      let match = FileMatcher.pickBestFileForHref(href, candidates);
      match.should.equal('/Users/barnaby/Documents/foundation/scss/deep/root/style.scss');
    });

    it('should return all candidates if no match found', function() {
      let href       = 'http://foundation.dev/style.css';
      let candidates = [
        '/Users/barnaby/Documents/foundation/unmatcheable1/style.scss',
        '/Users/barnaby/Documents/foundation/unmatcheable2/style.scss'
      ];
      let match = FileMatcher.pickBestFileForHref(href, candidates);
      match.should.eql(candidates);
    });

    it('should match files of type .css.scss', function() {
      let href       = 'http://yourgrind.dev/home.css';
      let candidates = [
        '/Users/nc/Workspace/yourgrind/app/assets/templates/home.css.scss',
        '/Users/nc/Workspace/yourgrind/app/assets/templates/application.css.scss'
      ];
      let match = FileMatcher.pickBestFileForHref(href, candidates);
      match.should.equal('/Users/nc/Workspace/yourgrind/app/assets/templates/home.css.scss');
    });

    it('should do somewhere', function() {
      let href = 'http://localhost:3000/styles/app.css';
      let candidates = [
        '/Users/barnaby/Projects/worldpay-backend/www/build/styles/app.css',
        '/Users/barnaby/Projects/worldpay-backend/www/source/styles/app.scss',
        '/Users/barnaby/Projects/worldpay-backend/www/source/styles/bourbon/css3/_appearance.scss'
      ];
      let match = FileMatcher.pickBestFileForHref(href, candidates);
      match.should.equal('/Users/barnaby/Projects/worldpay-backend/www/source/styles/app.scss');
    });

    it('should always choose the .scss file', function() {
      let href = "http://mac.dev/build/templates/panel.css";
      let candidates = [
        'templates/panel.css',
        '/panel.scss',
        '/panel/_choose_template.scss',
      ];
      let match = FileMatcher.pickBestFileForHref(href, candidates);
      match.should.equal("/panel.scss");
    });

    it("chooses the exactly basename-matching file, if present", function() {
      let href       = "http://localhost:3000/dev-assets/application.css?body=1";
      let candidates = [
        '/Users/some/app/assets/stylesheets/application.css.scss',
        '/Users/some/app/assets/stylesheets/application_for_ie.css.scss',
        '/Users/some/app/public/dev-assets/application-ad05cff88f5990d34b76724caf19a3d9.css',
        '/Users/some/app/public/dev-assets/application_for_ie-ad05cff88f5990d34b76724caf19a3d9.css'
      ];

      let match = FileMatcher.pickBestFileForHref(href, candidates);
      match.should.equal('/Users/some/app/assets/stylesheets/application.css.scss');
    });


    it("also chooses .scss files while in scoredMatching", function() {
      let href       = "http://localhost:8080/styleguide/css/styleguide.css?1398520261";
      let candidates = [
        '/Users/user/style-guides/styleguide-app/core/styleguide/css/styleguide-specific.css',
        '/Users/user/style-guides/styleguide-app/core/styleguide/css/styleguide-specific.scss',
        '/Users/user/style-guides/styleguide-app/core/styleguide/css/styleguide.css',
        '/Users/user/style-guides/styleguide-app/core/styleguide/css/styleguide.scss',
      ];

      let match = FileMatcher.pickBestFileForHref(href, candidates);
      match.should.equal('/Users/user/style-guides/styleguide-app/core/styleguide/css/styleguide.scss');
    });
  });
});

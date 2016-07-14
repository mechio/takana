import browser from '../../lib/browser';
import sinon from 'sinon';
import http from 'http';
import { client as WebSocketClient } from 'websocket';
import _ from 'underscore';
import Q from 'q';
import { EventEmitter } from 'events';


const PORT = 50001;

let promiseListen = function(eventemitter, event, options={}) {
  let deferred = Q.defer();
  let called   = false;
  let timeout  = options.timeout || 3000;

  eventemitter.once(event, function() {
    called = true;
    return deferred.resolve(arguments);
  });

  setTimeout(function() {
    if (!called) {
      return deferred.reject('timeout'); 
    }
  }
  , timeout);

  return deferred.promise;
};

let mockConnection = () => new EventEmitter();

let newBrowserConnection = function(projectName, callback) {
  let client = new WebSocketClient();

  client.on("connectFailed", function(error) {
    if (callback) {
      callback(e);
    }
    return console.error(`connect error: ${error.toString()}`);
  });
  
  client.on("connect", function(connection) {
    connection.sendMessage = function(event, data) {
      return this.sendUTF(JSON.stringify({
        event,
        data
      }
      ));
    };

    connection.on('message', function(message) {
      var m;
      if (message.binaryData) {
        m = JSON.parse(message.binaryData.toString());
      } else if (message.utf8Data) {
        m = JSON.parse(message.utf8Data);
      }

      return this.emit('message:parsed', m);
    });


    if (callback) {
      return callback(null, connection);
    }
  });

  return client.connect(`ws://localhost:${PORT}/browser?project_name=${projectName}`);
};


describe('browser.Manager', function() {
  before(function(done) {
    this.webServer      = http.createServer();
    this.browserManager = new browser.Manager(
      {webServer : this.webServer}
      // logger    : testLogger
    );
    this.browserManager.start();
    return this.webServer.listen(PORT, done);
  });

  after(function() {
    return this.webServer.close();
  });
  
  context('when a browsers connect and disconnect', () =>
    it('should adjust its internal state accordingly', function(done) {
      let { browserManager } = this;
      let browserList    = () => _.values(browserManager.browsers);

      browserList().should.be.empty;

      return Q.nfcall(newBrowserConnection, 'project1')
        .then((connection1) => {
          this.connection1 = connection1;
          browserList().length.should.equal(1);
          this.browser1    = browserList()[0];
          return Q.nfcall(newBrowserConnection, 'project2');
        })
        .then((connection2) => {
          this.connection2 = connection2;
          browserList().length.should.equal(2);
          return Q.nfcall(newBrowserConnection, 'project3');
        })
        .then((connection3) => {
          this.connection3 = connection3;
          browserList().length.should.equal(3);
          this.connection1.close();
          return setTimeout(() => {
            (browserManager.browsers[this.browser1.id] === undefined).should.be.true;
            this.connection2.close();
            this.connection3.close();
            return setTimeout(() => {
              browserList().should.be.empty
              done()
            }, 10)
          }

          , 10);
        })

        .fail(function(e) {
          throw e;
        })
        .done();
    })
  );
      
  let testStylesheetResolve = function(hrefName) {
    beforeEach(function(done) {
      this.payload = {};
      this.payload[hrefName] = 'http://reddit.com/stylesheet.css';

      return newBrowserConnection('some_project', (e, connection) => (this.connection = connection, done()));
    });

    afterEach(function() {
      return this.connection.close();
    });

    it('should emit a styleheet:resolve message', function(done) {
      this.browserManager.once('stylesheet:resolve', (data, callback) => {
        data.should.have.property(hrefName, this.payload[hrefName]);
        data.should.have.property('project_name', 'some_project');
        callback.should.be.a.Function;
        return done();
      });

      return this.connection.sendMessage('stylesheet:resolve', this.payload);
    });
    
    return context('after callback', function() {
      it('should send styleheet:resolved to the browser with the resolved id', function(done) {
        let resolvedId = '698726429736';

        this.browserManager.once('stylesheet:resolve', (data, callback) => {
          return callback(null, resolvedId);
        });
          
        this.connection.once('message:parsed', message => {
          message.event.should.equal('stylesheet:resolved');
          // message.data.project_name.should.equal('project_name')
          message.data[hrefName].should.equal(this.payload[hrefName]);
          message.data.id.should.equal(resolvedId);
          return done();
        });

        return this.connection.sendMessage('stylesheet:resolve', this.payload);
      });

      return context('with error', () =>
        it('should send styleheet:resolved to the browser with an error', function(done) {
          this.browserManager.once('stylesheet:resolve', (data, callback) => {
            return callback('error');
          });
            
          this.connection.once('message:parsed', message => {
            message.event.should.equal('stylesheet:resolved');
            message.data.should.have.property('error');
            return done();
          });

          return this.connection.sendMessage('stylesheet:resolve', this.payload);
        })
      );
    });
  };

  context('when the browser sends stylesheet:resolve', function() {
    context("with href property name href", () => testStylesheetResolve('href'));

    return context("with href property name takanaHref", () => testStylesheetResolve('takanaHref'));
  });

  context('when the browser sends styleheet:listen', function() {

    beforeEach(function(done) {
      this.payload = {id: 'stylesheet1'};
      return newBrowserConnection('some_project', (e, connection) => (this.connection = connection, done()));
    });

    afterEach(function() {
      return this.connection.close();
    });

    it('should add it to the watchers list', function(done) {
      let browserList    = () => _.values(this.browserManager.browsers);
      
      this.browserManager.once('stylesheet:listen', () => {
        browserList()[0].watchedStylesheets.should.containEql(this.payload.id);
        return done();
      });

      return this.connection.sendMessage('stylesheet:listen', this.payload);
    });
      
    
    return it('should emit styleheet:listen', function(done) {
      this.browserManager.once('stylesheet:listen', data => {
        data.should.have.property('id', this.payload.id);
        data.should.have.property('project_name', 'some_project');
        return done();
      });

      return this.connection.sendMessage('stylesheet:listen', this.payload);
    });
  });


  describe('watchedStylesheetsForProject', () =>
    it('should return the set of stylesheets that are being watched accross all browsers', function() {
      let browser1 = new browser.Browser({
        connection  : mockConnection(),
        projectName : 'a_project'
      }
      );

      let browser2 = new browser.Browser({
        connection  : mockConnection(),
        projectName : 'a_project'
      }
      );

      browser1.watchedStylesheets.push(1);
      browser2.watchedStylesheets.push(2);

      this.browserManager.addBrowser(browser1);
      this.browserManager.addBrowser(browser2);

      this.browserManager.watchedStylesheetsForProject('a_project').should.eql([1,2]);

      return this.browserManager.browsers = {};
    })
  );

  return describe('stylesheetRendered', function() {


    beforeEach(function(done) {
      this.payload = {id: 'stylesheet1'};
      return Q.nfcall(newBrowserConnection, 'project1')
       .then((connection1) => { 
          this.connection1 = connection1;
          return Q.nfcall(newBrowserConnection, 'project1');
        })
       .then((connection2) => { 
          this.connection2 = connection2;
          return Q.nfcall(newBrowserConnection, 'project1');
        })
       .then((connection3) => { 
          this.connection3 = connection3;
          return done();
        })
       .fail(function(e) { throw e; })
       .done();
    });

    afterEach(function() {
      this.connection1.close();
      this.connection2.close();
      this.connection3.close();
    });

    return it('should notify interested browsers that a render has occurred', function(done) {
      this.connection1.sendMessage('stylesheet:listen', {id: 'stylesheet1'});
      this.connection2.sendMessage('stylesheet:listen', {id: 'stylesheet1'});
      this.connection2.sendMessage('stylesheet:listen', {id: 'stylesheet2'});

      // Connection 3 should never get a message
      promiseListen(this.connection3, 'message:parsed', {timeout: 60})
        .fail(() => done())
        .done();

      return Q.allSettled([
        promiseListen(this.connection1, 'message:parsed'),
        promiseListen(this.connection2, 'message:parsed')

      ]).then(function(results) {
          let states = results.map( r => r.state );
          let values = results.map( r => r.value[0] );

          states.should.eql(['fulfilled', 'fulfilled']);

          return values.forEach(function(value) {
            value.should.have.property('event', 'stylesheet:updated');
            value.data.should.have.property('id', 'stylesheet1');
            return value.data.should.have.property('url', 'http://localhost:48626/stylesheet.css');
          });
        }).fail(function(e) { 
          throw e;
        }).done();

        setTimeout(() => {
          this.browserManager.stylesheetRendered('project1', 'stylesheet1', 'http://localhost:48626/stylesheet.css');
        }, 10)
    });
  });
});


  

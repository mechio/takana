var FakeServer, FakeWebSocket, setupFakeWebSocket, setupScriptTag;

FakeWebSocket = (function() {
  FakeWebSocket.SOCKET = null;

  FakeWebSocket.prototype.OPEN = 1;

  function FakeWebSocket(url) {
    this.url = url;
    this.constructor.SOCKET = this;
  }

  FakeWebSocket.prototype._open = function() {
    return this.onopen();
  };

  FakeWebSocket.prototype._message = function(event) {
    return this.onmessage(event);
  };

  FakeWebSocket.prototype.readyState = FakeWebSocket.OPEN;

  return FakeWebSocket;

})();

FakeServer = (function() {
  function FakeServer() {}

  return FakeServer;

})();

setupFakeWebSocket = function() {
  beforeEach(function() {
    this.websocket = WebSocket;
    return window.WebSocket = FakeWebSocket;
  });
  return afterEach(function() {
    var WebSocket;
    return WebSocket = this.websocket;
  });
};

setupScriptTag = function() {
  var injectScriptTag, removeScriptTag;
  injectScriptTag = function(options) {
    var el;
    if (options == null) {
      options = {};
    }
    options.projectName || (options.projectName = 'testProject');
    options.src || (options.src = 'http://localhost:48626/takana.js');
    el = document.createElement("script");
    el.setAttribute('data-project', options.projectName);
    el.setAttribute('src', options.src);
    el.setAttribute('id', 'test-script-tag');
    document.body.appendChild(el);
    return el;
  };
  removeScriptTag = function() {
    if (this.scriptTag && this.scriptTag.parentNode) {
      return this.scriptTag.parentNode.removeChild(this.scriptTag);
    }
  };
  beforeEach(function() {
    return this.scriptTag = injectScriptTag();
  });
  return afterEach(function() {
    return removeScriptTag();
  });
};

describe('Takana.Client', function() {
  return describe('start', function() {
    setupScriptTag();
    context('initialize configuration', function() {
      beforeEach(function() {
        return this.client = Takana.Client.start();
      });
      it('should find the Takana script tag', function() {
        return expect(this.client.scriptTag).to.eql(this.scriptTag);
      });
      it('should get the project name from the script tag', function() {
        return expect(this.client.projectName).to.eql('testProject');
      });
      it('should set the port', function() {
        return expect(Takana.Config.port).to.eql(48626);
      });
      return it('should set hostname based on scriptTag src', function() {
        return expect(Takana.Config.hostname).to.eql('localhost');
      });
    });
    return context('WebSocket', function() {
      setupFakeWebSocket();
      it('should connect to the Takana server', function() {
        this.client = Takana.Client.start();
        return expect(Takana.Server.instance.socket.readyState).to.equal(WebSocket.OPEN);
      });
      return describe('once connected', function() {
        beforeEach(function() {
          this.client = Takana.Client.start();
          this.socket = FakeWebSocket.SOCKET;
          this.socket.send = sinon.spy();
          return this.socket._open();
        });
        it('should send stylesheet:resolve message', function() {
          expect(this.socket.send.calledOnce).to.equal(true);
          return expect(this.socket.send.firstCall.args[0]).to.include('stylesheet:resolve');
        });
        return it('should create a project instance', function() {
          return expect(this.client.project.name).to.equal('testProject');
        });
      });
    });
  });
});

describe('Takana.Project', function() {
  beforeEach(function() {
    Takana.Server.instance = new FakeServer;
    this.bind = Takana.Server.instance.bind = sinon.stub();
    return this.send = Takana.Server.instance.send = sinon.stub();
  });
  it('should set the project name on initialize', function() {
    this.project = new Takana.Project({
      name: 'foo'
    });
    return expect(this.project.name).to.eql('foo');
  });
  it('should find all document stylesheets loaded via http and file protocols', function() {
    var el;
    el = document.createElement("style");
    el.setAttribute('type', 'text/css');
    document.body.appendChild(el);
    this.project = new Takana.Project({
      name: 'foobar'
    });
    return expect(this.project.documentStyleSheets).to.eql([document.styleSheets[0]]);
  });
  it('should ask the server to resolve all stylesheets', function() {
    this.project = new Takana.Project({
      name: 'foobar'
    });
    expect(this.project.documentStyleSheets).to.eql([document.styleSheets[0]]);
    expect(this.send).to.have.been.calledOnce;
    expect(this.send).to.have.been.calledWith("stylesheet:resolve");
    return expect(this.send.firstCall.args[1].href).to.include("http://" + window.location.host + "/base/test/css/test.css");
  });
  return it('should instantiate and start listening to a stylesheet once it has been resolved', function() {
    var styleSheet;
    this.project = new Takana.Project({
      name: 'foobar'
    });
    this.bind.firstCall.args[1]({
      id: 1,
      href: document.styleSheets[0].href
    });
    styleSheet = this.project.styleSheets["1"];
    expect(styleSheet.documentStyleSheet).to.equal(document.styleSheets[0]);
    expect(styleSheet.id).to.equal(1);
    return expect(this.send).to.have.been.calledWith("stylesheet:listen", {
      id: 1
    });
  });
});

describe('Takana.Server', function() {
  return it('should have some tests');
});

describe('Takana.StyleSheet', function() {
  beforeEach(function() {
    Takana.Server.instance = new FakeServer;
    this.bind = Takana.Server.instance.bind = sinon.stub();
    this.send = Takana.Server.instance.send = sinon.stub();
    return this.styleSheet = new Takana.StyleSheet({
      documentStyleSheet: document.styleSheets[0],
      id: 1
    });
  });
  describe('initialize', function() {
    return it('should set @el, @href, @id and @documentStyleSheet on initialize', function() {
      expect(this.styleSheet.documentStyleSheet).to.equal(document.styleSheets[0]);
      expect(this.styleSheet.el).to.equal(document.styleSheets[0].ownerNode);
      expect(this.styleSheet.href).to.equal(document.styleSheets[0].href);
      return expect(this.styleSheet.id).to.equal(1);
    });
  });
  describe('startListening', function() {
    beforeEach(function() {
      return this.styleSheet.startListening();
    });
    it('should inform the server it is listening', function() {
      return expect(this.send).to.have.been.calledWith("stylesheet:listen", {
        id: 1
      });
    });
    return it('should call "update" when the server calls stylesheet:update', function() {
      this.styleSheet.update = sinon.spy();
      this.bind.firstCall.args[1]({
        url: "",
        id: 1
      });
      return expect(this.styleSheet.update).to.have.been.calledOnce;
    });
  });
  return describe('update', function() {
    return it('should replace the old stylesheet with a new stylesheet linked to the server');
  });
});

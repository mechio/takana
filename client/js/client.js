window.Takana = {};

Takana.Config = (function() {
  function Config() {}

  return Config;

})();

Takana.Project = (function() {
  function Project(attributes) {
    this.name = attributes.name;
    this.documentStyleSheets = [];
    this.styleSheets = {};
    StyleSheetList.prototype.forEach = Array.prototype.forEach;
    document.styleSheets.forEach((function(_this) {
      return function(documentStyleSheet) {
        if (!!documentStyleSheet.href && (documentStyleSheet.href.match(/^http\:\/\/.*\.css.*/) || documentStyleSheet.href.match(/^file\:\/\/.*/))) {
          return _this.documentStyleSheets.push(documentStyleSheet);
        }
      };
    })(this));
    Takana.Server.instance.bind("stylesheet:resolved", (function(_this) {
      return function(event) {
        return _this.documentStyleSheets.forEach(function(documentStyleSheet) {
          var styleSheet;
          if (event.href === documentStyleSheet.href) {
            styleSheet = new Takana.StyleSheet({
              documentStyleSheet: documentStyleSheet,
              id: event.id
            });
            _this.styleSheets[event.id] = styleSheet;
            return styleSheet.startListening();
          }
        });
      };
    })(this));
    this.documentStyleSheets.forEach((function(_this) {
      return function(styleSheet) {
        return Takana.Server.instance.send("stylesheet:resolve", {
          href: styleSheet.href
        });
      };
    })(this));
  }

  return Project;

})();

Takana.Server = (function() {
  function Server(attributes, callback) {
    this.projectName = attributes.projectName;
    this.url = "ws://" + Takana.Config.hostname + ":" + Takana.Config.port + "/browser?project_name=" + this.projectName;
    this.socket = new WebSocket(this.url);
    this.socket.onopen = callback;
    this.socket.onmessage = (function(_this) {
      return function(event) {
        var message;
        message = JSON.parse(event.data);
        return _this.trigger(message.event, message.data);
      };
    })(this);
  }

  Server.prototype.send = function(event, data) {
    if (this.socket.readyState === WebSocket.OPEN) {
      return this.socket.send(JSON.stringify({
        event: event,
        data: data
      }));
    }
  };

  return Server;

})();

MicroEvent.mixin(Takana.Server);

Takana.StyleSheet = (function() {
  var stylesheetReloadTimeout;

  stylesheetReloadTimeout = 15000;

  function StyleSheet(attributes) {
    this.documentStyleSheet = attributes.documentStyleSheet;
    this.el = this.documentStyleSheet.ownerNode;
    this.href = this.documentStyleSheet.href;
    this.id = attributes.id;
  }

  StyleSheet.prototype.startListening = function() {
    Takana.Server.instance.send('stylesheet:listen', {
      id: this.id
    });
    return Takana.Server.instance.bind('stylesheet:updated', (function(_this) {
      return function(data) {
        if (data.id === _this.id) {
          return _this.update(data.url);
        }
      };
    })(this));
  };

  StyleSheet.prototype.onceCSSIsLoaded = function(clone, callback) {
    var callbackExecuted, executeCallback, timer;
    callbackExecuted = false;
    timer = null;
    executeCallback = (function(_this) {
      return function() {
        var additionalWaitingTime;
        if (callbackExecuted) {
          return;
        }
        clearInterval(timer);
        callbackExecuted = true;
        additionalWaitingTime = /AppleWebKit/.test(navigator.userAgent) ? 5 : 100;
        return setTimeout(callback, additionalWaitingTime);
      };
    })(this);
    clone.onload = (function(_this) {
      return function() {
        return executeCallback();
      };
    })(this);
    return setTimeout(executeCallback, stylesheetReloadTimeout);
  };

  StyleSheet.prototype.update = function(url) {
    var el, href, parentTagName;
    href = "http://" + Takana.Config.hostname + ":" + Takana.Config.port + "/" + url + "?" + (Date.now()) + "&href=" + (encodeURIComponent(this.href));
    el = document.createElement("link");
    el.setAttribute("type", "text/css");
    el.setAttribute("href", href);
    el.setAttribute("media", "all");
    el.setAttribute("rel", "stylesheet");
    parentTagName = document.body.contains(this.el) ? "body" : "head";
    document.getElementsByTagName(parentTagName)[0].insertBefore(el, this.el);
    return this.onceCSSIsLoaded(el, (function(_this) {
      return function() {
        _this.el.remove();
        return _this.el = el;
      };
    })(this));
  };

  return StyleSheet;

})();

Takana.Client = (function() {
  function Client() {
    this.projectName = 'default';
    Takana.Config.port = 48626;
    Takana.Config.hostname = 'localhost';
    Takana.Server.instance = this.server = new Takana.Server({
      projectName: this.projectName
    }, (function(_this) {
      return function() {
        return _this.project = new Takana.Project({
          name: _this.projectName
        });
      };
    })(this));
  }

  Client.start = function() {
    return new Takana.Client();
  };

  return Client;

})();

if (typeof __karma__ === "undefined") {
  window.takana = Takana.Client.start();
}

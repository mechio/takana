import sublime, sublime_plugin, time, os.path, json, threading, sys, socket, time
from threading import Thread

try:
  import socketserver
except ImportError:
  import SocketServer as socketserver

VERSION            = "Takana plugin v0.4"
DEBUG              = False
TAKANA_SERVER_PORT = 48628
st_ver             = 3000 if sublime.version() == '' else int(sublime.version())

print("***************************************")
print(VERSION)

class Error:
  region_key = 'error_dot'

  def __init__(self, file, line):
    self.file = file
    self.line = line
    self.view = None
  
  def update_view(self, view):
    self.clear()
    self.view = view
    self.show()

  def show(self):
    if not self.view:
      return 

    position = self.view.text_point(self.line - 1, 0)
    region   = sublime.Region(position, position)
    scope    = 'markup.deleted'
    icon     = 'dot'

    self.view.add_regions(self.region_key, [region], scope, icon)

  def clear(self):
    if not self.view:
      return 

    self.view.erase_regions(self.region_key)

class WindowWatcher(sublime_plugin.EventListener):
  def on_close(self, view):
    buffer_is_open = False

    if not view.is_dirty():
      return

    for w in sublime.windows():
      for v in w.views():
        if v.buffer_id() == view.buffer_id():
          buffer_is_open = True

    if not buffer_is_open:
      connection_manager.post(Message(['editor', 'reset'], {'path': view.file_name()}))

class ErrorManager(sublime_plugin.EventListener):
  errors = {}
  
  def on_activated_async(self, view):
    ErrorManager.register_view(view)
      
  @staticmethod
  def put(file, line):
    error = Error(file, line)
    ErrorManager.errors[file] = error 

    # Check if the current view is the one for our error
    ErrorManager.register_view(sublime.active_window().active_view())

  @staticmethod
  def remove(file):
    if file in ErrorManager.errors:
      ErrorManager.errors[file].clear()
      del ErrorManager.errors[file]

  @staticmethod
  def remove_all():
    keys = list(ErrorManager.errors.keys())
    for file in keys:
      ErrorManager.remove(file)

  @staticmethod
  def get(file):
    if file in ErrorManager.errors:
      return ErrorManager.errors[file]
    else:
      return None

  @staticmethod
  def register_view(view):
    filename = view.file_name()
    if filename:
      error = ErrorManager.get(filename)
      if error:
        error.update_view(view)

class TakanaTCPHandler(socketserver.BaseRequestHandler):
  def handle(self):
    message = self.request.recv(1024).decode("utf-8")
    message = Message.decode(message)

    if message.event == ['project', 'errors', 'add']:
      line  = message.data['error']['line']
      file  = message.data['error']['file']

      ErrorManager.put(file, line)

    if message.event == ['goto', 'line']:
      line  = message.data['line']
      file  = message.data['file']
      view  = sublime.active_window().open_file(file)
      time.sleep(0.1)
      view.run_command("goto_line", {"line": line} )

    elif message.event == ['project', 'errors', 'remove']:
      ErrorManager.remove_all()
      # ErrorManager.remove(message.data['error']['file'])


class TakanaSocketServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
  # Ctrl-C will cleanly kill all spawned threads
  daemon_threads      = True
  # much faster rebinding
  allow_reuse_address = True

  def __init__(self, server_address, RequestHandlerClass):
    socketserver.TCPServer.__init__(self, server_address, RequestHandlerClass)

if st_ver >= 3000:
  try:
    socket_server = TakanaSocketServer(('localhost', TAKANA_SERVER_PORT), TakanaTCPHandler)
    Thread(target=socket_server.serve_forever).start()
  except Exception as e:
    print('Takana: could not start server')

def plugin_unloaded():
  print('Takana: closing socket server...')
  if 'socket_server' in globals():
    socket_server.shutdown()
    socket_server.server_close()
  pass

class Message:
  def __init__(self, event, data):
    self.event = event
    self.data  = data

  def encode(self):
    return json.dumps(self.event + [self.data])
  
  @staticmethod
  def decode(data):
    message  = json.loads(data)
    data     = message.pop()
    event    = message

    return Message(event, data)

class Edit:
  file_name       = None
  file_extension  = None
  time            = None

  def __init__(self, file_name, text, time):
    self.file_name      = file_name
    self.text           = text
    self.time           = time

  def as_message(self):
    data = {
      'buffer'     : self.text,
      'path'       : self.file_name,
      'created_at' : self.time
    }

    return Message(['editor', 'update'], data)

class ConnectionManager:
  socket         = None
  last_message   = None

  def __init__(self):
    pass

  def __connect(self):
    print('Takana: connecting')
    try:
      serverHost = 'localhost'            # servername is localhost
      serverPort = 48627                  

      self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)    # create a TCP socket
      self.socket.settimeout(0.5)
      self.socket.connect((serverHost, serverPort)) # connect to server on the port
    except Exception as e:
      self.socket = None
      print('Takana: connection failed')

  def __post(self):
    msg = self.last_message.encode()

    try:
      if self.socket:
        print("Takana: sending update....")
        if st_ver >= 3000:
          self.socket.send(bytes(msg + "\n","utf8"))
        else:
          self.socket.sendall(msg + "\n")

      else:
        self.__connect()
    except socket.error as e:
      print('Takana: socket exception occurred:')
      print(e)      

      try:
        self.socket.shutdown(socket.SHUT_WR)
        self.socket.close()
      except Exception as e:
        print('Takana: socket already closed')

      self.socket = None
      
      print('Takana: Reconnecting')
      self.__connect()
    except socket.timeout:
      print('Takana: socket timeout')
    except IOError as e:
      print('Takana: socket ioerror')
      print(e)
    except Exception as e:
      print('Takana: post failed')
      print(e)

  def connect(self):
    self.__connect()

  def post(self, message):
    self.last_message = message
    self.__post()

connection_manager = ConnectionManager()
connection_manager.connect()

#
#
#
#  TakanaEditListener
#
#
#
class DelayedTimer:
  def __init__(self, delay, callback):
    self.delay = delay
    self.callback = callback
    self.lastRequest = 0
    self.scheduleTimer()
 
  def scheduleTimer(self):
    sublime.set_timeout(self.onTimer, int(self.delay * 1000))
 
  def onTimer(self):
    self.scheduleTimer()
    if self.lastRequest > 0 and self.lastRequest + self.delay < time.time(): 
      self.lastRequest = 0
      self.callback()
 
  def notify(self):
    self.lastRequest = time.time() 


class TakanaEditListener(sublime_plugin.EventListener):
  delay                = 0.035
  view                 = None
  supported_file_types = [".css", ".scss", ".sass", ".less"]
   
  def __init__(self):
    self.timer = DelayedTimer(self.delay, self.on_keystroke_end)


  def on_modified(self, view):
    if self.__should_monitor(view):

      # find & replace
      if view.command_history(0, True) == (u'', None, 1):
        print('forcing update')

      self.__on_change(view)


  def on_keystroke_end(self):
    timestamp = int(round(time.time() * 1000)) - (self.delay * 1000)

    edit = Edit(
      self.view.file_name(), 
      self.__text(),
      timestamp
    )

    connection_manager.post(edit.as_message())

    if DEBUG:
      print('time_since_keystroke: ' + str( int(round(time.time() * 1000)) - timestamp - (self.delay * 1000) ))

  def __on_change(self, view):
    self.view = view
    self.timer.notify() 

  def __should_monitor(self, view):
    should_monitor = False

    if view and view.file_name():
      file_name, file_extension = os.path.splitext(view.file_name())
      should_monitor = file_extension in self.supported_file_types

    return should_monitor


  def __text(self):
    return self.view.substr(sublime.Region(0, self.view.size()))

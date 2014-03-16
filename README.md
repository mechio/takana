![Takana Logo](https://raw.github.com/mechio/takana/master/takana.png)

By [mech.io](http://mech.io/)

Takana is a Sass/CSS live-editor. It lets you see your SCSS and CSS style changes live, in the browser, as you type them. 


## Getting started guide


##### NOTE: Currently, takana only supports OSX and Sublime Text 2 & 3.

### 1. Install the CLI

The CLI is the way you'll start, stop and add projects to takana. It's an npm package that you can install as follows:

```
npm install -g takana
```
This will put the `takana` command in your system path, allowing it to be run from any directory.

### 2. Start the server

The server is responsible for receiveing Sass source code from the editor, and pushing the compiled CSS output to the browser. It's started as follows:

```
takana start
```
The server opens two ports: 1) a TCP socket on port `48627`, that receives Sass from the editor, and 2) a HTTP port on `48626` that pushes CSS to the browser via WebSocket.

### 3. Install the Sublime Text plugin
The plugin is responsible for pushing the state of the sublime buffer to the  server. It can be installed in one of 2 ways:


```
# via the command line
takana sublime:install

# or, via package control
Sublime Text -> Preferences -> Package Control: Install Package -> Takana
```


### 4. Add your project
Takana needs to know where your stylesheets are located in order to live-compile them. You can a project from the CLI:

```
takana add /path/to/project_folder
```
Projects have a `path` and are uniquely identified by `name`. For convinience, the above command assigns the name as the last component of the projects path (here it would be `project_folder`).


### 5. Add the JavaScript snippit to your HTML

Now all you need to do is add the JavaScript snippit to any page you want to live update:

```
<script type="text/javascript" data-project="YOUR_PROJECT_NAME" src="http://localhost:48626/takana.js"></script>
```

Just replace `YOUR_PROJECT_NAME` with the name of your project. If you're unsure, you can list all projects by running `takana list` from the command line.

### 6. You're all set

Open the web page that you pasted the snippit into on the previous step. Then open one of it's referenced stylesheets in Sublime and start live-editing!

## Usage

```
$ takana

  Usage: takana [options] [command]

  Commands:

    start                  start the server
    stop                   stop the server
    status                 print server status
    list                   list all projects
    add <path> [name]      add a project
    remove <name>          remove a project
    js <name>              print the js snippet for a project
    sublime:install        install the Sublime Text plugin - also available via Package Control

  Options:

    -h, --help     output usage information
    -V, --version  output the version number
```

## Troubleshooting

### Make sure that your editor and browser are connected
TODO
```
$ takana status
```

### Check that your stylesheets are being matched
TODO
```
$ tail -100 ~/log/takana.log
```

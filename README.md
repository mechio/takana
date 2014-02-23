![Devise Logo](https://raw.github.com/mechio/takana/master/takana.png?token=480673__eyJzY29wZSI6IlJhd0Jsb2I6bWVjaGlvL3Rha2FuYS9tYXN0ZXIvdGFrYW5hLnBuZyIsImV4cGlyZXMiOjEzOTM3OTM4NjV9--39a09bc005c68415cb371a0f48a366bc58952ac0)

By [mech.io](http://mech.io/).

![](https://api.travis-ci.com/mechio/takana.png?token=6GpqfNU3uWoTskgz3zwc)

Takana lets you see your SCSS and CSS style changes live, in the browser, as you type them. Currently it supports Sublime Text 2 & 3 on OSX.

### Installation

```
npm install -g takana && takana sublime:install
```

### Usage

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

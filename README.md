![Takana Logo](https://raw.github.com/mechio/takana/master/takana.png)

[![Build Status](https://travis-ci.org/mechio/takana.svg?branch=master&style=flat)](https://travis-ci.org/mechio/takana)
[![npm version](https://badge.fury.io/js/takana.svg)](http://badge.fury.io/js/takana)

[http://usetakana.com](http://usetakana.com)

Takana is a Sass/CSS live-editor. It lets you see your SCSS and CSS style changes live, in the browser, as you type them.

## Requirements

- Currently, Takana supports OSX, Linux and Sublime Text 2 & 3.
- Takana uses [libsass](https://github.com/hcatlin/libsass) under the hood, if you're using [node-sass](https://github.com/andrew/node-sass) you'll be fine. However, if you're using the ruby compiler, you may need to refactor your code to get it running with libsass.


## Getting Started

### Using the CLI

#### 1. Install the CLI

Install the `takana` command to your system path:

```
$ npm install -g takana
```

#### 2. Start takana

Run takana by specifying the root of your project directory:

```
$ takana /path/to/project_folder
```

#### 3. Add the JavaScript snippit to your HTML

Now add the JavaScript snippit to any page you want to live update:

```html
<script type="text/javascript" src="http://localhost:48626/takana.js"></script>
<script type="text/javascript">
  takanaClient.run({
    host: 'localhost:48626' // optional, defaults to localhost:48626
  });
</script>
```

#### 4. You're all set

Finally open the web page that you pasted the snippit into on the previous step. Then open one of its referenced stylesheets in Sublime and start live-editing!

### Using Grunt

We maintain a grunt plugin for easy integration with Takana. Head over to [mechio/grunt-takana](https://github.com/mechio/grunt-takana) for instructions on getting started.



### Contributing

You can install your development folder with

    $ npm install

Please adjust unit tests, if you change code. Run tests with:

    $ npm test

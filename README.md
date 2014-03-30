![Takana Logo](https://raw.github.com/mechio/takana/master/takana.png)

By [mech.io](http://mech.io/)

Takana is a Sass/CSS live-editor. It lets you see your SCSS and CSS style changes live, in the browser, as you type them. 

## Getting started guide

##### NOTE: Currently, takana only supports OSX and Sublime Text 2 & 3.

### 1. Install the CLI

Install the `takana` command to your system path:

```
npm install -g takana
```

### 2. Start takana

Run takana by specifying the root of your project directory:

```
takana /path/to/project_folder
```

### 3. Add the JavaScript snippit to your HTML

Now add the JavaScript snippit to any page you want to live update:

```
<script type="text/javascript" src="http://localhost:48626/takana.js"></script>
```

### 4. You're all set

Finally open the web page that you pasted the snippit into on the previous step. Then open one of it's referenced stylesheets in Sublime and start live-editing!

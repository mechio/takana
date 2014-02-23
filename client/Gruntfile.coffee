module.exports = (grunt) ->
  grunt.initConfig

    concat:
      client: 
        src: [
          "bower_components/microevent/microevent.js"
          "js/client.js"
        ]
        dest: "js/takana.js"

    wrap:
      basic:
        src: "js/takana.js"
        dest: "js/takana.js"
        options:
          wrapper: [
            "(function() {\n",
            "})()\n"
          ]

    copy:
      client:
        src: 'js/takana.js'
        dest: '../www/takana.js'

    "closure-compiler": 
      client:
        js: ["js/takana.js"] 
        jsOutputFile: "../www/takana.js"
        noreport: true
        closurePath: "vendor/closure-compiler/"
        options: 
          compilation_level: "SIMPLE_OPTIMIZATIONS"
          warning_level: "DEFAULT"

    coffee:
      client:
        options: 
          bare: true

        files: 
          "js/client.js": [
            "src/takana.coffee"
            "src/client/*.coffee"
            "src/client.coffee"
          ]

      test:
        options:
          bare: true

        files:
          "js/test.js": ["test/support.coffee", "test/**/*.coffee"]

    karma:
      unit:
        configFile: 'karma.conf.js'

    watch:
      client:
        files: ['**/*.coffee']
        tasks: ['build', 'karma:unit:run']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-karma'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-wrap'
  grunt.loadNpmTasks 'grunt-closure-compiler'
  grunt.loadNpmTasks 'grunt-contrib-copy'

  grunt.registerTask 'build', [
    'coffee'
    'concat'
    'wrap'
    'copy'
  ]
  grunt.registerTask 'build:production', [
    'build'
    'closure-compiler'
  ]
  grunt.registerTask 'default', 'build'

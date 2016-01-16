_           = require 'lodash'
browserSync = require 'browser-sync'
bump        = require 'gulp-bump'
coffee      = require 'gulp-coffee'
coffeelint  = require 'gulp-coffeelint'
concat      = require 'gulp-concat'
del         = require 'del'
filter      = require 'gulp-filter'
fs          = require 'fs'
git         = require 'gulp-git'
gulp        = require('gulp-help')(require 'gulp')
gulpif      = require 'gulp-if'
gutil       = require 'gulp-util'
karma       = require 'karma'
open        = require 'gulp-open'
path        = require 'path'
rename      = require 'gulp-rename'
runsequence = require 'run-sequence'
sassLint    = require 'gulp-sass-lint'
sauce       = require 'sauce-connect-launcher'
selenium    = require 'selenium-standalone'
shell       = require 'gulp-shell'
sourcemaps  = require 'gulp-sourcemaps'
tag         = require 'gulp-tag-version'
watch       = require 'gulp-watch'
webdriver   = require 'gulp-webdriver'
webpack     = require 'webpack-stream'
yaml        = require 'js-yaml'
yargs       = require 'yargs'



# Grab command line arguments.
argv = yargs.argv



# Pull Webpack plugin references.
UglifyJsPlugin = webpack.webpack.optimize.UglifyJsPlugin



# Load and parse the build configuration.
config = yaml.safeLoad fs.readFileSync __dirname + '/config/build.yaml'



# Load the webpack config file.
webpackConfig = require __dirname + '/config/webpack.config.coffee'
webpackConfig.plugins ?= []



# Default all config options, then remove the `default` key because we shouldn't
# use it.
_.forEach config.env, (value, key) ->
  if key is 'default' then return
  _.defaultsDeep config.env[key], config.env.default
config.env = _.omit config.env, 'default'



# Set the build environment (default to "debug").
env = 'debug'
_.forEach ['production', 'test'], (v) ->
  if argv[v] then env = v



# Returns nicely formatted bundle options for `gulp help`.
getBundleOptions = (type) ->
  return {
    'production': "#{type} for production environment."
    'test': "#{type} for testing environment."
    'debug': "#{type} for development environment."
    'skip-uglifyjs': "Skip compression with UglifyJS."
  }



# Compiles all CoffeeScript files into a single concatenated JavaScript file.
gulp.task 'coffee', 'Transpiles CoffeeScript to JavaScript.', ->
  gulp.src config.path.src.coffee + '/**/*.coffee'
  .pipe sourcemaps.init()
  .pipe coffee()
  .pipe sourcemaps.write config.path.maps.js
  .pipe gulp.dest config.path.target
  .on 'error', gutil.log



# Compiles all CoffeeScript selenium test files.
gulp.task 'coffee:selenium', false, ->
  gulp.src config.path.test.selenium + '/**/*.coffee'
  .pipe coffee()
  .pipe gulp.dest config.path.test.selenium



# Bundles this project as defined by the Webpack configuration file.
gulp.task 'bundle', 'Bundles project files using Webpack.', ->
  # Merge-in the environment configuration.
  _.merge webpackConfig, config.env[env].webpack

  # Instantiate production Webpack plugins.
  uglifyJSPlugin = new UglifyJsPlugin(config.env[env].uglify)

  # If we're not explicitly skipping UglifyJS compression, add-in the plugin.
  if !argv.skipUglifyjs
    webpackConfig.plugins.push uglifyJSPlugin

  switch env
    when 'test'
      entryRoot = config.path.test.unit
    else
      entryRoot = config.path.src.coffee



  gulp.src entryRoot + '/' + webpackConfig.entry
  .pipe webpack webpackConfig
  .pipe gulp.dest config.path.target
  .on 'error', gutil.log
, {
  options: getBundleOptions('Bundle')
}



# Cleans project paths.
gulp.task 'clean', 'Cleans project paths.', ['clean:test'], ->
  cleanPaths = [
    config.path.target
    config.path.tmp
    config.path.doc
  ]
  del cleanPaths



# Cleans-up compiled selenium test files.
gulp.task 'clean:selenium', false, ->
  del config.path.test.selenium + '/**/*.js'



gulp.task 'clean:test', 'Cleans up test files.', ['clean:selenium']



# Builds the entire project.
gulp.task 'build', 'Builds the project.', ->
  runsequence ['lint', 'clean'], 'bundle'
, {
  options: getBundleOptions('Build')
}



# Simple task to tag the git repo at it's current version as-specified by
# the package.json file.
gulp.task 'tag', 'Tags the project at it\'s current version.', ->
  gulp.src ['./package.json']
  .pipe tag()



# Register task to generate project documentation using Groc.
gulp.task 'doc', 'Generates Groc documentation.', shell.task [
    './node_modules/groc/bin/groc'
  ]



# Generates and opens the documentation in the default browser.
gulp.task 'opendocs', 'Opens the docs in the defaul browser', ['doc'], ->
  gulp.src 'doc/index.html'
  .pipe open()



# Starts Webpack in watch mode.
gulp.task 'watch', 'Enables watch-mode for Webpack', ->
  webpackConfig.watch = true
  gulp.start 'bundle'
, {
  options: getBundleOptions('Watch and bundle')
}



# Lints all SASS source files.
gulp.task 'sasslint', 'Lints SASS files.', ->
  gulp.src config.path.src.sass + '/**/*.sass'
  .pipe sassLint()
  .pipe sassLint.format()
  .pipe sassLint.failOnError()



# Lints all CoffeeScript source files.
gulp.task 'coffeelint', 'Lints CoffeeScript files.', ->
  gulp.src config.path.src.coffee + '/**/*.coffee'
  .pipe coffeelint
    optFile: './.coffeelint.json'
  .pipe coffeelint.reporter()



# Builds the entire project.
gulp.task 'lint', 'Lints the project.', ->
  runsequence 'sasslint', 'coffeelint'



# Generate tasks for bumping project versions and tagging.
_.each {
  patch: 'Bump, commit, and tag the package patch version.'
  minor: 'Bump, commit, and tag the package minor version.'
  major: 'Bump, commit, and tag the package major version.'
}, (description, importance) ->
  gulp.task 'bump:' + importance, description, ->
    gulp.src ['./package.json']
    .pipe bump({type: importance})
    .pipe gulp.dest './'
    .pipe git.commit "Bump package #{importance} version."
    .pipe filter 'package.json'
    .pipe tag()



gulp.task 'karma', false, (done) ->
  cb = -> done()
  console.log !argv.watch
  options =
    configFile: __dirname + '/../karma.conf.coffee'
    singleRun: !argv.watch
  new karma.Server(options, cb).start()



# Simple task to tag the git repo at it's current version as-specified by
gulp.task 'test:karma', 'Run Karma tests.', ->
  env = 'test'
  runsequence ['clean'], 'bundle', 'karma'
, {
  'watch': 'Watch for file changes and re-run tests.'
}


# Starts a webserver which serves files from the configured
# `config.path.target` directory.
gulp.task 'serve', 'Serve files located in target directory.', (done) ->
  browserSync
    logLevel: 'silent'
    notify: false
    open: false
    port: 9000
    codeSync: false
    server:
      baseDir: config.path.target
    ui: false
  , done



# Runs selenium tests remotely on SauceLabs
gulp.task 'test:sauce', 'Run selenium tests on SauceLabs.', [
  'sauce:connect', 'coffee:selenium'], ->
  gulp.src 'test/config/wdio-saucelabs.conf.js'
  .pipe webdriver()
  .once 'end', ->
    sauce.child.close()
    browserSync.exit()



# Launches SauceConnect, creating a private testing VPN between localhost
# (where the testing web server is located) and SauceLabs.
gulp.task 'sauce:connect', false, ['serve'], (done) ->
  credentials =
    username: process.env.SAUCE_USERNAME
    accessKey: process.env.SAUCE_ACCESS_KEY
    verbose: true
    verboseDebugging: true
    #doctor: true
    logger: gutil.log
  sauce credentials, (err, child) ->
    if err
      gutil.log err
    else
      sauce.child = child
    done()



# Runs selenium tests on a local selenium server.
gulp.task 'test:selenium', 'Run selenium tests.', [
  'serve', 'selenium:start', 'coffee:selenium'], ->
  gulp.src 'test/config/wdio-local.conf.js'
  .pipe webdriver()
  .once 'end', ->
    selenium.child.kill()
    browserSync.exit()



# Installs the local standalone selenium installation.
# **Note: The `logger` property is set to an empty function which suppresses
# output. If you're having problems installing selenium, replace it with
# `gutil.log`.
gulp.task 'selenium:install', false, (done) ->
  selenium.install
    logger: ->
  , done



# Starts-up the standalone selenium installation.
gulp.task 'selenium:start', false, ['selenium:install'], (done) ->
  selenium.start (err, child) ->
    if err then return
    selenium.child = child
    done()

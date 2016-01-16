_           = require 'lodash'
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
shell       = require 'gulp-shell'
sourcemaps  = require 'gulp-sourcemaps'
tag         = require 'gulp-tag-version'
watch       = require 'gulp-watch'
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
  .pipe concat(config.app.main)
  .pipe coffee()
  .pipe sourcemaps.write config.path.maps.js
  .pipe gulp.dest config.path.target
  .on 'error', gutil.log



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
      entryRoot = config.path.test.unit.coffee
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
gulp.task 'clean', 'Cleans project paths.', ->
  cleanPaths = [
    config.path.target
    config.path.tmp
    config.path.doc
  ]
  del cleanPaths



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
  gulp.task importance, description, ->
    gulp.src ['./package.json']
    .pipe bump({type: importance})
    .pipe gulp.dest './'
    .pipe git.commit "Bump package #{importance} version."
    .pipe filter 'package.json'
    .pipe tag()



gulp.task 'run-karma', false, (done) ->
  cb = -> done()
  console.log !argv.watch
  options =
    configFile: __dirname + '/../karma.conf.coffee'
    singleRun: !argv.watch
  new karma.Server(options, cb).start()



# Simple task to tag the git repo at it's current version as-specified by
gulp.task 'karma', 'Run Karma tests.', ->
  env = 'test'
  runsequence ['clean'], 'bundle', 'run-karma'
, {
  'watch': 'Watch for file changes and re-run tests.'
}

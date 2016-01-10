_           = require 'lodash'
bump        = require 'gulp-bump'
clean       = require 'gulp-clean'
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
path        = require 'path'
rename      = require 'gulp-rename'
runsequence = require 'run-sequence'
sourcemaps  = require 'gulp-sourcemaps'
tag         = require 'gulp-tag-version'
uglify      = require 'gulp-uglify'
watch       = require 'gulp-watch'
webpack     = require 'webpack-stream'
yaml        = require 'js-yaml'
yargs       = require 'yargs'


# Grab command line arguments.
argv = yargs.argv


# Load and parse the build configuration.
config = yaml.safeLoad fs.readFileSync __dirname + '/config/build.yaml'


# Load the webpack config file.
webpackConfig = require __dirname + '/config/webpack.config.coffee'


# Set production/debug options.
if argv.production
  _.merge webpackConfig, config.options.production.webpack
else
  _.merge webpackConfig, config.options.debug.webpack


# Compiles all CoffeeScript files into a single concatenated JavaScript file.
gulp.task 'coffee', 'Transpiles CoffeeScript to JavaScript.', ->
  gulp.src config.path.src.coffee + '/**/*.coffee'
  .pipe sourcemaps.init()
  .pipe concat(config.app.main)
  .pipe coffee()
  .pipe sourcemaps.write config.path.maps.js
  .pipe gulp.dest config.path.target.js
  .on 'error', gutil.log


# Bundles this project as defined by the Webpack configuration file.
gulp.task 'bundle', 'Bundles project files using Webpack.', ->
  gulp.src config.path.src.coffee + '/' + config.app.entry
  .pipe webpack webpackConfig
  .pipe gulp.dest config.path.target.js
  .on 'error', gutil.log
, {
  options:
    'production': 'Bundle for production environment.'
}


# Compresses the transpiled JavaScript using UglifyJS.
gulp.task 'uglify', 'Minifies JavaScript files.', ->
  gulp.src config.path.target.js + '/**/*.js'
  .pipe rename (p) ->
    p.extname = '.min.js'
  .pipe sourcemaps.init loadMaps: true
  .pipe uglify()
  .pipe sourcemaps.write config.path.maps.js
  .pipe gulp.dest config.path.target.js
  .on 'error', gutil.log


# Cleans project paths.
gulp.task 'clean', 'Cleans project paths.', ->
  cleanPaths = _.values(config.path.target).concat [config.path.tmp]
  del cleanPaths
  .then (paths) ->
    gutil.log 'Deleted files and folders: \n\t', paths.join('\t\n')


# Builds the entire project.
gulp.task 'build', 'Builds the project.', ->
  runsequence 'clean', 'bundle', 'uglify'
, {
  options:
    'production': 'Build for production environment.'
}


# Generate tasks for bumping project versions and tagging.
_.each {
  patch: 'Bump the package patch version.'
  minor: 'Bump the package minor version.'
  major: 'Bump the package major version.'
}, (description, importance) ->
  gulp.task importance, description, ->
    gulp.src ['./package.json']
    .pipe bump({type: importance})
    .pipe gulp.dest './'
    .pipe git.commit "Bumps package #{importance} version."
    .pipe filter 'package.json'
    .pipe tag_version()
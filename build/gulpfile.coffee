_           = require 'lodash'
fs          = require 'fs'
path        = require 'path'
yargs       = require 'yargs'
gulp        = require 'gulp'
sourcemaps  = require 'gulp-sourcemaps'
coffeelint  = require 'gulp-coffeelint'
clean       = require 'gulp-clean'
watch       = require 'gulp-watch'
bump        = require 'gulp-bump'
tag         = require 'gulp-tag-version'
git         = require 'gulp-git'
gulpif      = require 'gulp-if'
filter      = require 'gulp-filter'
coffee      = require 'gulp-coffee'
concat      = require 'gulp-concat'
gutil       = require 'gulp-util'
yaml        = require 'js-yaml'
del         = require 'del'
uglify      = require 'gulp-uglify'
rename      = require 'gulp-rename'
webpack     = require 'webpack-stream'
runsequence = require 'run-sequence'


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
gulp.task 'coffee', ->
  gulp.src config.path.src.coffee + '/**/*.coffee'
  .pipe sourcemaps.init()
  .pipe concat(config.app.main)
  .pipe coffee()
  .pipe sourcemaps.write config.path.maps.js
  .pipe gulp.dest config.path.target.js
  .on 'error', gutil.log


# Bundles this project as defined by the Webpack configuration file.
gulp.task 'bundle', ->
  gulp.src config.path.src.coffee + '/' + config.app.entry
  .pipe webpack webpackConfig
  .pipe gulp.dest config.path.target.js
  .on 'error', gutil.log


# Compresses the transpiled JavaScript using UglifyJS.
gulp.task 'uglify', ->
  gulp.src config.path.target.js + '/**/*.js'
  .pipe rename (p) ->
    p.extname = '.min.js'
  .pipe sourcemaps.init loadMaps: true
  .pipe uglify()
  .pipe sourcemaps.write config.path.maps.js
  .pipe gulp.dest config.path.target.js
  .on 'error', gutil.log


# Cleans project paths.
gulp.task 'clean', ->
  cleanPaths = _.values(config.path.target).concat [config.path.tmp]
  del cleanPaths
  .then (paths) ->
    gutil.log 'Deleted files and folders: \n\t', paths.join('\t\n')



gulp.task 'compile', ->
  runsequence 'clean', 'bundle', 'uglify'
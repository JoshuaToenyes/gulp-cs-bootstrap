fs          = require 'fs'
gulp        = require 'gulp'
sourcemaps  = require 'gulp-sourcemaps'
coffeelint  = require 'gulp-coffeelint'
clean       = require 'gulp-clean'
watch       = require 'gulp-watch'
bump        = require 'gulp-bump'
tag         = require 'gulp-tag-version'
git         = require 'gulp-git'
filter      = require 'gulp-filter'
coffee      = require 'gulp-coffee'
concat      = require 'gulp-concat'
gutil       = require 'gulp-util'
yaml        = require 'js-yaml'
del         = require 'del'
uglify      = require 'gulp-uglify'
rename      = require 'gulp-rename'
webpack     = require 'webpack-stream'
webpackCfg  = require './webpack.config.coffee'


# Load and parse the build configuration.
config = yaml.safeLoad fs.readFileSync 'config/build.yaml'


# Compiles all CoffeeScript files into a single concatenated JavaScript file.
gulp.task 'coffee', ->
  gulp.src config.path.src + '/**/*.coffee'
  .pipe sourcemaps.init()
  .pipe concat(config.app.main)
  .pipe coffee()
  .pipe sourcemaps.write config.path.maps
  .pipe gulp.dest config.path.target
  .on 'error', gutil.log


gulp.task 'pack', ->
  gulp.src config.path.src + '/' + config.app.entry
  .pipe webpack webpackCfg
  .pipe gulp.dest config.path.target
  .on 'error', gutil.log


gulp.task 'uglify', ->
  gulp.src config.path.target + '/' + config.app.main
  .pipe rename config.app.min
  .pipe sourcemaps.init loadMaps: true
  .pipe uglify()
  .pipe sourcemaps.write config.path.maps
  .pipe gulp.dest config.path.target
  .on 'error', gutil.log

gulp.task 'clean', ->
  cleanPaths = [
    config.path.tmp
    config.path.target]
  del cleanPaths
  .then (paths) ->
    gutil.log 'Deleted files and folders: \n\t', paths.join('\t\n')
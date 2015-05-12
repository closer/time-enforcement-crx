gulp       = require('gulp')
clean      = require('gulp-clean')
changed    = require('gulp-changed')
coffee     = require('gulp-coffee')
cson       = require('gulp-cson')
zip        = require('gulp-zip')
editJson   = require('gulp-json-editor')
browserify = require('browserify')
source     = require('vinyl-source-stream')
es         = require('event-stream')
exec       = require('child_process').exec
Q          = require('q')

gulp.task 'default', ['build']

endpoints = ['global', 'options']

gulp.task 'coffee', ->
  gulp.src 'src/**/*.coffee'
    .pipe changed 'src', extension: '.js'
    .pipe coffee emitError: false
    .pipe gulp.dest 'js'

gulp.task 'compile', ['coffee', 'dependency'], ->
  es.merge.apply es,
    endpoints.map (path)->
      browserify "./js/#{path}.js"
        .bundle()
        .pipe source "#{path}.js"
        .pipe gulp.dest 'build'

gulp.task 'dependency', ->
  gulp.src 'bower_components/zepto/zepto.js'
    .pipe gulp.dest 'js/lib'

gulp.task 'assets', ->
  gulp.src 'assets/**/*'
    .pipe gulp.dest 'build'

gulp.task 'html', ->
  gulp.src 'html/**/*'
    .pipe gulp.dest 'build'

tag = ->
  q = Q.defer()

  exec 'git describe --tags --always --dirty', (err, stdout, stderr)->
    if err
      q.reject err
      return

    q.resolve stdout.replace /\n/, ''

  q.promise

version = ->
  tag().then (tag)->
    tag.replace /-(\d+)/, '.$1'
      .replace /-g[0-9a-f]+/, ''
      .replace /-dirty/, ''

gulp.task 'manifest-compile', ->
  gulp.src 'src/manifest.cson'
    .pipe cson()
    .pipe gulp.dest 'build'

gulp.task 'manifest', ['manifest-compile'], ->
  version().then (version)->
    gulp.src 'build/manifest.json'
      .pipe editJson version: version
      .pipe gulp.dest 'build'

gulp.task 'build', ['clean', 'manifest', 'compile', 'static']
gulp.task 'static', ['html', 'assets']

gulp.task 'zip', ['build'], (cb)->
  version().then (version)->
    gulp.src 'build/**/*'
      .pipe zip "TimeEnforcement-#{version}.zip"
      .pipe gulp.dest 'release'

gulp.task 'clean', ->
  gulp.src 'build/*'
    .pipe clean()

gulp.task 'watch', ->
  gulp.watch 'src/manifest.cson', ['manifest']
  gulp.watch 'src/**/*.coffee', ['compile']
  ['html', 'assets'].forEach (file)->
    gulp.watch "#{file}/**/*", [file]

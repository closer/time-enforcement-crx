gulp       = require('gulp')
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

gulp.task 'coffee', ->
  gulp.src 'src/**/*.coffee'
    .pipe changed 'src', extension: '.js'
    .pipe coffee emitError: false
    .pipe gulp.dest 'build/src'

gulp.task 'browserify', ['coffee', 'copy'], ->
  es.merge.apply es,
    [ 'global.js', 'options.js' ].map (path)->
      browserify "./build/src/#{path}"
        .bundle()
        .pipe source path
        .pipe gulp.dest 'build/pkg'

gulp.task 'copy', ->
  gulp.src 'bower_components/zepto/zepto.js'
    .pipe gulp.dest 'build/src/lib'

gulp.task 'assets', ->
  gulp.src 'src/assets/**/*'
    .pipe gulp.dest 'build/pkg'

gulp.task 'html', ->
  gulp.src 'src/html/**/*'
    .pipe gulp.dest 'build/pkg'

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
    .pipe gulp.dest 'build/src'

gulp.task 'manifest', ['manifest-compile'], ->
  version().then (version)->
    gulp.src 'build/src/manifest.json'
      .pipe editJson version: version
      .pipe gulp.dest 'build/pkg'

gulp.task 'build', ['manifest', 'script', 'static']
gulp.task 'script', ['browserify']
gulp.task 'static', ['html', 'assets']

gulp.task 'zip', ['build'], (cb)->
  version().then (version)->
    gulp.src 'build/pkg/**/*'
      .pipe zip "TimeEnforcement-#{version}.zip"
      .pipe gulp.dest 'relaese'

gulp.task 'watch', ->
  gulp.watch 'src/manifest.cson', ['manifest']
  gulp.watch 'src/**/*.coffee', ['browserify']

  ['html', 'assets'].forEach (file)->
    gulp.watch "src/#{file}/**/*", [file]

gulp = require 'gulp'
open = require 'gulp-open'
wait = require 'gulp-wait'
sass = require 'gulp-sass'
coffee = require 'gulp-coffee'
livereload = require 'gulp-livereload'

spawn = require('child_process').spawn
node = null


gulp.task 'sass', ->
  gulp.src('sass/**/*.scss')
    .pipe(sass())
    .pipe(gulp.dest('public/css'))

gulp.task 'coffee', ->
  gulp.src('coffee/**/*.coffee')
    .pipe(coffee())
    .pipe(gulp.dest('public/js'))

gulp.task 'html', ->
  gulp.src('html/**/*.html')
    .pipe(gulp.dest('public'))

gulp.task 'vendor', ->
  gulp.src('vendor/**')
    .pipe(gulp.dest('public'))

gulp.task 'watch-client', ->
  livereload.listen()
  gulp.watch('sass/**', ['sass']).on 'change', livereload.changed
  gulp.watch('coffee/**', ['coffee']).on 'change', livereload.changed
  gulp.watch('html/**', ['html']).on 'change', livereload.changed

gulp.task 'client', ['sass', 'coffee', 'html', 'vendor', 'watch-client'], ->
  gulp.src('public/index.html')
    .pipe(wait(2000))
    .pipe(open('', url: 'http://localhost:3000'))


gulp.task 'watch-server', ->
  gulp.watch 'server.coffee', ['server']

gulp.task 'server', ['watch-server'], ->
  node.kill()  if node
  node = spawn 'coffee', ['server.coffee'], {stdio: 'inherit'}
  node.on 'close', (code) -> gulp.log 'An error occured' if code is 8

process.on 'exit', -> node.kill() if node


gulp.task 'default', ['server', 'client']
gulp = require 'gulp'
open = require 'gulp-open'
wait = require 'gulp-wait'
sass = require 'gulp-sass'
coffee = require 'gulp-coffee'

spawn = require('child_process').spawn
node = null


gulp.task 'sass', ->
  gulp.src('sass/**/*.sass')
    .pipe(sass())
    .pipe(gulp.dest('public/css'))

gulp.task 'coffee', ->
  gulp.src('coffee/**/*.coffee')
    .pipe(coffee())
    .pipe(gulp.dest('public/js'))

gulp.task 'client', ['sass', 'coffee'], ->
  gulp.src('public/index.html')
    .pipe(wait(2000))
    .pipe(open('http://localhost:3000', {app:"chromium"}))


gulp.task 'server', ->
  node.kill()  if node
  node = spawn 'coffee', ['server.coffee'], {stdio: 'inherit'}
  node.on 'close', (code) -> gulp.log 'An error occured' if code is 8

process.on 'exit', -> node.kill() if node


gulp.task 'default', ['server', 'client'], ->
  gulp.watch 'server.coffee', ['server']
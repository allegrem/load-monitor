gulp = require 'gulp'
open = require 'gulp-open'
wait = require 'gulp-wait'

spawn = require('child_process').spawn
node = null


gulp.task 'client', ->
  gulp.src('index.html')
    .pipe(wait(2000))
    .pipe(open('http://localhost:3000', {app:"chromium"}))

gulp.task 'server', ->
  node.kill()  if node
  node = spawn 'coffee', ['server.coffee'], {stdio: 'inherit'}
  node.on 'close', (code) -> gulp.log 'An error occured' if code is 8

gulp.task 'default', ['server', 'client'], ->
  gulp.watch 'server.coffee', ['server']

process.on 'exit', -> node.kill() if node
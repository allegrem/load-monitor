gulp = require 'gulp'
spawn = require('child_process').spawn
node = null


gulp.task 'server', ->
  node.kill()  if node
  node = spawn 'coffee', ['server.coffee'], {stdio: 'inherit'}
  node.on 'close', (code) -> gulp.log 'An error occured' if code is 8

gulp.task 'default', ['server'], ->
  gulp.watch 'server.coffee', ['server']

process.on 'exit', -> node.kill() if node
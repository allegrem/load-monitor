express = require('express')
app = express()
http = require('http').createServer(app)
io = require('socket.io')(http)
os = require 'os'


app.use express.static(__dirname + '/public')

io.on 'connection', (socket) ->
  console.log 'a user is connected'
  emitLoadAvg socket  #emit initial load
  socket.on 'disconnect', -> console.log 'user disconnected'

http.listen 3000, -> console.log 'listening on *:3000'


emitLoadAvg = (socket) ->
  load = os.loadavg()
  dest = socket || io  #if no socket given, broadcast to all clients
  console.log 'emit load', load
  dest.emit 'load', load

setInterval emitLoadAvg, 5000
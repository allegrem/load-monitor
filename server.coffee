app = require('express')()
http = require('http').createServer(app)
io = require('socket.io')(http)

app.get '/', (req, res) -> res.sendFile __dirname+'/index.html'

io.on 'connection', (socket) ->
  console.log 'a user is connected'
  socket.on 'disconnect', -> console.log 'user disconnected'

http.listen 3000, -> console.log 'listening on *:3000'
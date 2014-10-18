console.log 'hello world'


socket = io()

socket.on 'load', (load) ->
  console.log "load", load
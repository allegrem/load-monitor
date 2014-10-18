console.log 'hello world'


jaugeTpl = Handlebars.compile $("#gauge-template").html()
jaugesConfig = [
  {title: 'last 1 minute', id: '#gauge1min', index: 0},
  {title: 'last 5 minutes', id: '#gauge5min', index: 1},
  {title: 'last 15 minutes', id: '#gauge15min', index: 2}
]

socket = io()
source = Rx.Observable.fromEvent socket, 'load'

source.subscribe (load) ->
  $(jauge.id).html jaugeTpl(title: jauge.title, value: load[jauge.index])  for jauge in jaugesConfig
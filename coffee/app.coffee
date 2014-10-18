# Pre compile gauge template
gaugeTpl = Handlebars.compile $("#gauge-template").html()

# Gauge configuration (will be used to render the gauge template)
gaugesConfig = [
  {title: 'last 1 minute', id: '#gauge1min', index: 0},
  {title: 'last 5 minutes', id: '#gauge5min', index: 1},
  {title: 'last 15 minutes', id: '#gauge15min', index: 2}
]

# Connect with socket.io
socket = io()
loadSource = Rx.Observable.fromEvent socket, 'load'

# Extract average load during the last 2 minutes
averageLoadSource = loadSource
  .select (loads) -> loads[0] #extract the first value of the table
  .bufferWithTime(25000, 5000) #buffer the values emitted during the last 25 seconds
  .select (buffer) ->
    buffer.reduce(((prev, curr) -> prev + curr), 0) / buffer.length  #compute the average value of the buffer

# Update gauges
loadSource.subscribe (load) ->
  $(gauge.id).html gaugeTpl(title: gauge.title, value: load[gauge.index])  for gauge in gaugesConfig

averageLoadSource.subscribe (load) ->
  console.log "load", load
  $('#gaugeavg').html gaugeTpl(title: 'average last 2 minutes', value: load)
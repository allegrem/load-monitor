#### Templates & Configuration

# Pre compile gauge template
gaugeTpl = Handlebars.compile $("#gauge-template").html()

# Gauge configuration (will be used to render the gauge template)
gaugesConfig = [
  {title: 'last 1 minute', id: '#gauge1min', index: 0},
  {title: 'last 5 minutes', id: '#gauge5min', index: 1},
  {title: 'last 15 minutes', id: '#gauge15min', index: 2}
]


#### Streams

# Connect with socket.io
socket = io()
loadSource = Rx.Observable.fromEvent socket, 'load'

# Extract average load during the last 2 minutes
averageLoadSource = loadSource
  .select (loads) -> loads[0] #extract the first value of the table
  .windowWithTime(15000, 5000) #buffer the values emitted during the last 25 seconds
  .selectMany (win) -> win.average() #compute the average load

# Binary stream indicating if the server is overloaded (avg load > 1)
overloadSource = averageLoadSource
  .select (load) -> load > 1 #turn the load stream into a binary stream (true if the avg load is greater than 1)
  .startWith(false) #at the beginning, there is no overload
  .distinctUntilChanged() #only keep the value when it changes


#### View

# Update gauges
loadSource.subscribe (load) ->
  $(gauge.id).html gaugeTpl(title: gauge.title, value: load[gauge.index])  for gauge in gaugesConfig

averageLoadSource.subscribe (load) ->
  console.log "load", load
  $('#gaugeavg').html gaugeTpl(title: 'average last 2 minutes', value: load)

# Update background color
overloadSource.subscribe (overload) ->
    $('body').toggleClass 'overload', overload
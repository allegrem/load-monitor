#### Templates

# Pre compile templates
gaugeTpl = Handlebars.compile $('#gauge-template').html()
logEntryTpl = Handlebars.compile $('#log-entry-template').html()


#### Streams

# Connect with socket.io
socket = io()
loadsSource = Rx.Observable.fromEvent socket, 'load'

# Extract average load during the last 2 minutes
averageLoadSource = loadsSource
  .select (loads) -> loads.filter((load) -> load.timespan is 1)[0].value #extract the value of the 1 min timespan
  .windowWithTime(15000, 5000) #buffer the values emitted during the last 25 seconds
  .selectMany (win) -> win.average() #compute the average load

# Binary stream indicating if the server is overloaded (avg load > 1)
overloadSource = averageLoadSource
  .select (load) -> load > 1 #turn the load stream into a binary stream (true if the avg load is greater than 1)
  .startWith(false) #at the beginning, there is no overload
  .distinctUntilChanged() #only keep the value when it changes


#### View

# Update gauges
loadsSource.subscribe (loads) ->
  $('#gauges').html gaugeTpl(loads: loads)

averageLoadSource.subscribe (load) ->
  $('#gaugeavg').html gaugeTpl(loads: [{timespan: 2, value: load}])

# Update background color
overloadSource.subscribe (overload) ->
  $('body').toggleClass 'overload', overload

# Append log entries
overloadSource
  .skip(1)  #we don't want to log the initial 'false' value
  .subscribe (overload) ->
    entry =
      time: new Date()
      message: if overload then "High load alert!" else "High load alert recovered"
      level: if overload then "alert" else "info"
    $('#log').prepend logEntryTpl(entry)
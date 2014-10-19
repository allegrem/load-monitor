#### Templates

# Pre compile templates
gaugeTpl = Handlebars.compile $('#gauge-template').html()
logEntryTpl = Handlebars.compile $('#log-entry-template').html()


#### Streams

# Connect with socket.io
socket = io()
loadsSource = Rx.Observable.fromEvent socket, 'load'

# Extract the load value of the 1 min timespan
instantLoadSource = loadsSource
  .select (loads) -> loads.filter((load) -> load.timespan is 1)[0].value

# Extract average load during the last 2 minutes
averageLoadSource = instantLoadSource
  .windowWithTime(15000, 5000) #buffer the values emitted during the last 25 seconds
  .selectMany (win) -> win.average() #compute the average load

# Binary stream indicating if the server is overloaded (avg load > 1)
overloadSource = averageLoadSource
  .select (load) -> load > 0.6 #turn the load stream into a binary stream (true if the avg load is greater than 1)
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
  .startWith(true, false, true, false)  # REMOVE ME !!!!!!!!!
  .subscribe (overload) ->
    entry =
      time: new Date()
      message: if overload then "High load alert!" else "High load alert recovered"
      level: if overload then "alert" else "info"
    $('#log').prepend logEntryTpl(entry)

# Chart
dateToLabel = (date) -> "#{date.getHours()}:#{date.getMinutes()}:#{date.getSeconds()}"
ctx = $("#loadChart").get(0).getContext("2d")
loadChartData =
  labels: ['','']
  datasets: [
    {
      fillColor: "rgba(220,220,220,0.2)",
      strokeColor: "rgba(220,220,220,1)",
      pointColor: "rgba(220,220,220,1)",
      pointStrokeColor: "#fff",
      pointHighlightFill: "#fff",
      pointHighlightStroke: "rgba(220,220,220,1)",
      data: [0.0001,0.0001]
    },
    {
      fillColor: "rgba(0,0,0,0)",
      strokeColor: "rgba(255,0,0,1)",
      pointColor: "rgba(0,0,0,0)",
      pointStrokeColor: "rgba(0,0,0,0)",
      pointHighlightFill: "rgba(0,0,0,0)",
      pointHighlightStroke: "rgba(0,0,0,0)",
      data: [1,1]
    }
  ]
loadChartOpts =
  scaleBeginAtZero: true
  showTooltips: false
loadChart = new Chart(ctx).Line loadChartData, loadChartOpts
instantLoadSource.subscribe (load) ->
  loadChart.addData [load, 1], dateToLabel(new Date())
  loadChart.removeData(0)  if loadChart.datasets[0].points.length > 12
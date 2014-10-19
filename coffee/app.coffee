#### Templates

# Pre compile templates
gaugeTpl = Handlebars.compile $('#gauge-template').html()
logEntryTpl = Handlebars.compile $('#log-entry-template').html()

# Keep two decimals
Handlebars.registerHelper 'truncate', (value) -> value.toFixed(2)

# Return the level (alert, warning, normal) corresponding to a value
Handlebars.registerHelper 'valueToLevel', (value) ->
  return 'alert' if value >= 1
  return 'warning' if value >= 0.75
  return 'normal'

# Pluralize a word depending on a value
# If plural is omitted, the plural form will be the singular form with an 's'
Handlebars.registerHelper 'pluralize', (value, singular, plural) ->
  plural = singular + 's'  if typeof(plural) isnt String
  if value > 1 then plural else singular


#### Streams

# Connect with socket.io
socket = io()
loadsSource = Rx.Observable.fromEvent socket, 'load'

# Extract the load value of the 1 min timespan
instantLoadSource = loadsSource
  .select (loads) -> loads.filter((load) -> load.timespan is 1)[0].value

# Extract average load during the last 2 minutes
averageLoadSource = instantLoadSource
  .windowWithCount(12,1) #buffer the last 12 values (last 2 minutes)
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

# Chart
dateToLabel = (date) -> "#{date.getHours()}:#{date.getMinutes()}:#{date.getSeconds()}"
ctx = $("#loadChart").get(0).getContext("2d")
ctx.canvas.width = 0.9 * window.innerWidth
ctx.canvas.height = 0.5 * window.innerHeight
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
class AirPollutionControls
  setupCompleted: false
  setup: ->
    if @setupCompleted
      $("#controls").show()
    else
      # do other stuff
      @setupGraph()
      @setupPlayback()
      @setupSliders()
      @setupAirTempIndicator()

      $("#controls").show()
      @setupCompleted = true

  pollutionGraph: null
  setupGraph: ->
    if $("#output-graphs").length == 0 then return


    # ### begin copy/pasted block; how to modularize?

    appendKeyToGraph = (graphId, top, labelInfo) ->
      $graph = $ "##{graphId}"
      $graph.append '<a href="#" class="show-key">show key</a>'
      $graph.find('.show-key').click ->
        unless $("##{graphId}-key").length > 0
          $key = $("<div id=\"#{graphId}-key\" class=\"key\"><a class=\"icon-remove-sign icon-large\"></a><canvas></canvas></div>").appendTo($(document.body)).draggable()
          canvas = $key.find('canvas')[0]
          $key.height 18 * (labelInfo.length + 1)
          canvas.height = $key.outerHeight()
          canvas.width = $key.outerWidth()
          drawKey $key.find('canvas')[0], labelInfo

        $key = $ "##{graphId}-key"
        $key.css
          left: '370px',
          top: "#{top}px"
        .show()
        .on 'click', 'a', ->
          $(this).parent().hide()

    # Called by appendKeyToGraph to draw the actual lines
    drawKey = (canvas, labelInfo) ->
      # center the lines verticaly
      y = 0.5 * (canvas.height - 20 * (labelInfo.length - 1))
      ctx = canvas.getContext '2d'
      ctx.fillStyle = 'black'
      ctx.font = '12px "Helvetica Neue", Helvetica, sans-serif'
      ctx.lineWidth = 2
      for label in labelInfo
        ctx.strokeStyle = "rgb(#{label.color.join(',')})"
        ctx.beginPath()
        ctx.moveTo 10, y
        ctx.lineTo 60, y
        ctx.stroke()
        ctx.fillText label.label, 70, y + 3
        y += 20

    # ### end copy/pasted block


    ABM.model.graphSampleInterval = 10
    defaultOptions =
      title:  "Primary (brown), Secondary (orange) Pollutants"
      xlabel: "Time (ticks)"
      ylabel: "AQI (Air Quality Index)"
      xmax:   2100
      xmin:   0
      ymax:   300
      ymin:   0
      xTickCount: 7
      yTickCount: 10
      xFormatter: "0f"
      yFormatter: "0f"
      sample: 10
      realTime: true
      fontScaleRelativeToParent: true
      dataColors: [
         AirPollutionModel.pollutantColors.primary,
         AirPollutionModel.pollutantColors.secondary
      ]

    @pollutionGraph = LabGrapher '#pollution-graph', defaultOptions

    labelInfo = [
      { color: AirPollutionModel.pollutantColors.primary, label: "Primary Pollutants" },
      { color: AirPollutionModel.pollutantColors.secondary, label: "Secondary Pollutants" }
    ]

    appendKeyToGraph 'pollution-graph', 20, labelInfo

    # start the graph at 0,0
    @pollutionGraph.addSamples [[0],[0]]

    # hack (for now) to make y-axis non-draggable
    $(".draggable-axis[x=24]").css("cursor","default").attr("pointer-events", "none")
    $(".y text").css("cursor", "default")

    $(document).on AirPollutionModel.GRAPH_INTERVAL_ELAPSED, =>
      p = ABM.model.primaryAQI()
      s = ABM.model.secondaryAQI()
      @pollutionGraph.addSamples [[p], [s]]
      $("#raw-primary").text(ABM.model.primary.length)
      $("#raw-secondary").text(ABM.model.secondary.length)
      $("#aqi-primary").text(p)
      $("#aqi-secondary").text(s)

  setupPlayback: ->
      $(".icon-pause").hide()
      $(".icon-play").show()
      $("#controls").show()
      $("#play-pause-button").button()
      .click =>
        @startStopModel()
      $("#reset-button").button()
      .click =>
        @resetModel()
      $("#playback").buttonset()

  setupSliders: ->
    $("#wind-slider").slider
      orientation: 'horizontal'
      min: -100
      max: 100
      step: 10
      value: ABM.model.windSpeed
      slide: (evt, ui)->
        ABM.model.setWindSpeed ui.value

    $("#cars-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 10
      step: 1
      value: ABM.model.numCars
      slide: (evt, ui)->
        ABM.model.setNumCars ui.value

    $("#sunlight-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 10
      step: 1
      value: ABM.model.sunlightAmount
      slide: (evt, ui)->
        ABM.model.setSunlight ui.value
      change: (evt, ui)->
        ABM.model.setSunlight ui.value

    $("#rain-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 6
      step: 1
      value: ABM.model.rainRate
      slide: (evt, ui)->
        ABM.model.setRainRate ui.value
      change: (evt, ui)->
        ABM.model.setRainRate ui.value

    $("#cars-pollution-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 100
      step: 5
      value: ABM.model.carPollutionRate
      slide: (evt, ui)->
        ABM.model.carPollutionRate = ui.value

    $("#cars-pollution-control-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 100
      step: 5
      value: 100 - ABM.model.carPollutionRate
      slide: (evt, ui)->
        ABM.model.carPollutionRate = 100 - ui.value

    $("#cars-electric-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 100
      step: 10
      value: ABM.model.electricCarPercentage
      slide: (evt, ui)->
        ABM.model.setElectricCarPercentage ui.value

    $("#factories-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 5
      step: 1
      value: ABM.model.getNumFactories()
      slide: (evt, ui)->
        ABM.model.setNumFactories ui.value

    $("#factories-pollution-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 100
      step: 5
      value: ABM.model.factoryPollutionRate
      slide: (evt, ui)->
        ABM.model.factoryPollutionRate = ui.value

    $("#factories-pollution-control-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 100
      step: 5
      value: 100 - ABM.model.factoryPollutionRate
      slide: (evt, ui)->
        ABM.model.factoryPollutionRate = 100 - ui.value

    $("#temperature-slider").slider
      orientation: 'horizontal'
      min: 0
      max: 100
      step: 10
      value: ABM.model.temperature
      slide: (evt, ui)->
        ABM.model.temperature = ui.value

  setupAirTempIndicator: ->
    $(document).on AirPollutionModel.WIND_SPEED_CHANGED, ->
      if ABM.model.windSpeed > 0
        opacity = 0.5 - (ABM.model.windSpeed/60)
        $("#lower-air-temperature").stop().animate({opacity: opacity})
      else
        $("#lower-air-temperature").stop().animate({opacity: 1})

  startStopModel: ->
    @stopModel() unless @startModel()

  stopModel: ->
    if ABM.model.anim.animStop
      return false
    else
      ABM.model.stop()
      $(".icon-pause").hide()
      $(".icon-play").show()
      return true

  startModel: ->
    if ABM.model.anim.animStop
      ABM.model.start()
      $(".icon-pause").show()
      $(".icon-play").hide()
      return true
    else
      return false

  resetModel: ->
    @stopModel()
    $(".icon-pause").hide()
    $(".icon-play").show()

    @pollutionGraph.reset()
    @pollutionGraph.addSamples [[0],[0]]

    setTimeout ->
      ABM.model.reset()
    , 10

window.AirPollutionControls = AirPollutionControls

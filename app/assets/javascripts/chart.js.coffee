class @Chart

  constructor: (@options = {}) ->
    @_setupChart()
    @_fetchData()

  _setupChart: ->
    @$el = $('#amchart')
    @$el.removeClass().addClass(@type + ' loading')

  _fetchData: ->
    $.ajax("/sites/#{@options.siteID}/chart_data.json?type=#{@chart_data_type}&days=#{@options.numDays}&start_date=#{@options.startDate}&end_date=#{@options.endDate}").done((data) =>
        if data.length > 1
          @_renderData(data)
        else
          @$el.addClass('insufficient-data')
        return
      ).fail(=>
        @_failedAttempt()
      ).always(=>
        @$el.removeClass('loading')
      )

    $.ajax("/sites/#{@options.siteID}/tabs_data?start_date=#{@options.startDate}&end_date=#{@options.endDate}").done((data) =>
      @_renderTabs(data)
    ).fail(=>
      @_failedAttempt()
    ).always(=>
      @$el.removeClass('loading')
    )

  _renderTabs: (data) ->
    $('.tabs-data').html(data)
    if typeof(window.CurrentChart) == "undefined"
      $(".chart-wrapper .chart-block").first().addClass('activated')
    else
      $('.chart-block.' + window.CurrentChart).addClass('activated')

  _renderData: (data) ->
    @chart = AmCharts.makeChart "amchart",
      type: "serial"
      theme: "none"
      colors: [@color]
      dataProvider: data
      categoryField: "date"
      fontFamily: "proxima-nova"
      autoMargins: false
      marginBottom: 40
      marginRight: 25
      marginLeft: 60
      marginTop: 25

      graphs: [
        id: "g1"
        bullet: "round"
        lineThickness: 2
        valueField: "value"
        type: "line"
        bulletBorderAlpha: 1
        hideBulletsCount: 50
        bulletColor: "#FFFFFF"
        useLineColorForBulletBorder: true
        balloonText: "<i class='#{@icon}'></i> [[value]] #{@text}"
      ]

      balloon:
        color: '#ffffff'
        offsetY: 40
        fontSize: 12
        fillAlpha: 1
        shadowAlpha: 0
        fillColor: @color
        borderThickness: 0
        verticalPadding: 5
        fixedPosition: true
        animationDuration: 0
        horizontalPadding: 10

      categoryAxis:
        dashLength: 1
        tickLength: 0
        color: "#c6c6c6"
        axisThickness: 2
        gridColor: "#f6f6f6"
        axisColor: "#c6c6c6"

      valueAxes: [
        gridAlpha: 1
        tickLength: 0
        color: "#c6c6c6"
        position: "left"
        gridThickness: 1
        axisThickness: 0
        gridColor: "#f6f6f6"
        showFirstLabel: false
        integersOnly: true
      ]

  _failedAttempt: ->
    @$el.addClass('failed')
